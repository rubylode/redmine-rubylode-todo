import { Controller } from "@hotwired/stimulus"
import { application } from "controllers/application"

// The to-do list: every change is one request to the plugin, then the list is fetched again,
// so what is on the page is always what the server stored.
class TodoController extends Controller {
  static targets = ["list", "message", "newLine"]
  static values = { linesPath: String, pageUrl: String, confirmCloseSubtree: String, confirmReopenSubtree: String, composerPlaceholder: String, tooManyLines: String, failure: String }

  connect() {
    this.closedThisVisit = new Set()
    this.foldedIds = this.loadFoldedIds()
    this.applyFolds()
  }

  // Folding is a per-browser convenience, so it lives in localStorage, which may be unavailable.
  get foldStorageKey() {
    return `redmine_todo.folded.${this.linesPathValue}`
  }

  loadFoldedIds() {
    try {
      return new Set(JSON.parse(window.localStorage.getItem(this.foldStorageKey) || "[]"))
    } catch (error) {
      return new Set()
    }
  }

  saveFoldedIds() {
    try {
      window.localStorage.setItem(this.foldStorageKey, JSON.stringify([...this.foldedIds]))
    } catch (error) {
      // folding still works for this visit
    }
  }

  foldableLines() {
    return [...this.listTarget.querySelectorAll("li[data-ticket-id]")].filter((line) => line.querySelector(":scope > ul"))
  }

  applyFolds() {
    this.foldableLines().forEach((line) => {
      const folded = this.foldedIds.has(line.dataset.ticketId)
      line.classList.toggle("todo-folded", folded)
      line.querySelector(":scope > .todo-line-text .todo-fold")?.setAttribute("aria-expanded", String(!folded))
    })
  }

  toggleFold(event) {
    const ticketId = this.ticketIdOf(event.currentTarget)
    if (this.foldedIds.has(ticketId)) {
      this.foldedIds.delete(ticketId)
    } else {
      this.foldedIds.add(ticketId)
    }
    this.saveFoldedIds()
    this.applyFolds()
  }

  collapseAll(event) {
    event.preventDefault()
    this.foldableLines().forEach((line) => this.foldedIds.add(line.dataset.ticketId))
    this.saveFoldedIds()
    this.applyFolds()
  }

  expandAll(event) {
    event.preventDefault()
    this.foldedIds.clear()
    this.saveFoldedIds()
    this.applyFolds()
  }

  async addLine(event) {
    if (event.key === "ArrowUp" && this.newLineTarget.value === "") {
      event.preventDefault()
      const lastLine = this.visibleLines().pop()
      if (lastLine) this.startEditById(lastLine.dataset.ticketId)
      return
    }
    if (event.key !== "Enter" || event.isComposing) return
    event.preventDefault()
    const subject = this.newLineTarget.value.trim()
    if (subject === "") return

    if (await this.send("POST", this.linesPathValue, { subject })) {
      this.newLineTarget.value = ""
      await this.refresh()
    }
  }

  edit(event) {
    this.startEdit(event.currentTarget)
  }

  startEditById(ticketId) {
    const subjectElement = this.listTarget.querySelector(`li[data-ticket-id="${ticketId}"] > .todo-line-text .todo-subject`)
    if (subjectElement) this.startEdit(subjectElement)
  }

  // Editing a line in place, with the keys of a notes app:
  //   Enter            save, then open a new line below
  //   Cmd/Ctrl+Enter   save, then close or reopen the line
  //   Up / Down        save, then edit the line above or below
  //   Alt+Up / Alt+Down       move the line up or down among its siblings
  //   Alt+Right / Alt+Left    nest it under the line above, or move it back out
  //   Escape           cancel
  startEdit(subjectElement) {
    const original = subjectElement.textContent
    const input = document.createElement("input")
    input.type = "text"
    input.className = "todo-subject-input"
    input.value = original
    subjectElement.replaceWith(input)
    input.focus()

    const line = input.closest("li")
    const ticketId = line.dataset.ticketId
    let finished = false
    const finish = async (save, next = {}) => {
      if (finished) return
      finished = true
      // Read where the neighbours are before anything is saved and the list is drawn again.
      const neighborId = next.offset ? this.visibleNeighborId(line, next.offset) : null
      const moveParams = next.direction ? this.moveParamsFor(line, next.direction) : null

      let changed = false
      const subject = input.value.trim()
      if (save && subject !== "" && subject !== original) {
        if (!(await this.send("PATCH", this.linePath(ticketId), { subject }))) return input.replaceWith(subjectElement)
        changed = true
      }
      if (moveParams) {
        if (!(await this.send("PATCH", `${this.linePath(ticketId)}/move`, moveParams))) {
          return changed ? this.refresh() : input.replaceWith(subjectElement)
        }
        changed = true
      }
      if (changed) {
        await this.refresh()
      } else {
        input.replaceWith(subjectElement)
      }

      if (next.addBelow) this.openComposerAfter(this.listTarget.querySelector(`li[data-ticket-id="${ticketId}"]`))
      if (next.toggle) this.toggleLineCheckbox(ticketId)
      if (neighborId) this.startEditById(neighborId)
      if (next.offset === 1 && !neighborId) this.newLineTarget.focus()
      if (moveParams) this.startEditById(ticketId)
    }

    input.addEventListener("keydown", (keyEvent) => {
      if (keyEvent.isComposing) return
      const { key, altKey } = keyEvent
      if (key === "Enter" && (keyEvent.metaKey || keyEvent.ctrlKey)) {
        keyEvent.preventDefault()
        finish(true, { toggle: true })
      } else if (key === "Enter") {
        keyEvent.preventDefault()
        finish(true, { addBelow: true })
      } else if (key === "Escape") {
        finish(false)
      } else if (altKey && key.startsWith("Arrow")) {
        keyEvent.preventDefault()
        const direction = key.replace("Arrow", "").toLowerCase()
        if (this.moveParamsFor(line, direction)) finish(true, { direction })
      } else if (key === "ArrowUp" || key === "ArrowDown") {
        keyEvent.preventDefault()
        finish(true, { offset: key === "ArrowUp" ? -1 : 1 })
      }
    })
    input.addEventListener("blur", () => finish(true))
  }

  toggleLineCheckbox(ticketId) {
    const checkbox = this.listTarget.querySelector(`li[data-ticket-id="${ticketId}"] > .todo-line-text .todo-checkbox`)
    if (!checkbox) return
    checkbox.checked = !checkbox.checked
    this.toggle({ currentTarget: checkbox })
  }

  visibleLines() {
    return [...this.listTarget.querySelectorAll("li.todo-line")].filter((line) => line.offsetParent !== null)
  }

  visibleNeighborId(line, offset) {
    const lines = this.visibleLines()
    return lines[lines.indexOf(line) + offset]?.dataset.ticketId || null
  }

  // The parent and the sibling to put the line in front of, for Alt+arrow moves. Null when the move makes no sense.
  moveParamsFor(line, direction) {
    const siblingId = (element) => element?.dataset.ticketId
    const previous = line.previousElementSibling
    const next = line.nextElementSibling
    const parentLine = line.parentElement.closest("li[data-ticket-id]")
    if (direction === "up" && siblingId(previous)) {
      return { parent_id: line.dataset.parentId || "", before_id: previous.dataset.ticketId }
    }
    if (direction === "down" && siblingId(next)) {
      return { parent_id: line.dataset.parentId || "", before_id: siblingId(next.nextElementSibling) || "" }
    }
    if (direction === "right" && siblingId(previous)) {
      return { parent_id: previous.dataset.ticketId, before_id: "" }
    }
    if (direction === "left" && parentLine) {
      const grandparentLine = parentLine.parentElement.closest("li[data-ticket-id]")
      return { parent_id: grandparentLine?.dataset.ticketId || "", before_id: siblingId(parentLine.nextElementSibling) || "" }
    }
    return null
  }

  // The composer is a new, empty line. Enter saves it and opens the next one below, Tab nests it under the
  // line above, Shift+Tab moves it back out, Escape (or Enter on an empty line) stops. Where the composer sits
  // in the list decides the new ticket's parent and place.
  addChild(event) {
    event.preventDefault()
    const line = event.currentTarget.closest("li")
    this.foldedIds.delete(line.dataset.ticketId)
    this.saveFoldedIds()
    this.applyFolds()
    this.openComposer(this.nestedListOf(line), null)
  }

  openComposerAfter(line) {
    if (line) this.openComposer(line.parentElement, line.nextElementSibling)
  }

  openComposer(list, beforeNode) {
    this.closeComposer()
    const composer = document.createElement("li")
    composer.className = "todo-composer"
    const input = document.createElement("input")
    input.type = "text"
    input.className = "todo-composer-input"
    input.placeholder = this.composerPlaceholderValue
    composer.append(input)
    list.insertBefore(composer, beforeNode)
    input.focus()

    input.addEventListener("keydown", (keyEvent) => {
      if (keyEvent.isComposing) return
      if (keyEvent.key === "Enter") {
        keyEvent.preventDefault()
        this.submitComposer(composer, input)
      } else if (keyEvent.key === "Escape" || (keyEvent.key === "Backspace" && input.value === "")) {
        keyEvent.preventDefault()
        this.closeComposer()
      } else if (keyEvent.key === "Tab") {
        keyEvent.preventDefault()
        keyEvent.shiftKey ? this.outdentComposer(composer, input) : this.indentComposer(composer, input)
      } else if ((keyEvent.key === "ArrowUp" || keyEvent.key === "ArrowDown") && input.value === "") {
        keyEvent.preventDefault()
        this.leaveComposerToward(composer, keyEvent.key === "ArrowUp" ? -1 : 1)
      }
    })
    input.addEventListener("paste", (pasteEvent) => {
      const parentLine = composer.parentElement.closest("li[data-ticket-id]")
      this.pasteLines(pasteEvent, parentLine?.dataset.ticketId || "", composer.nextElementSibling?.dataset.ticketId || "")
    })
    input.addEventListener("blur", () => {
      if (this.movingComposer || composer.dataset.submitting || !composer.isConnected) return
      input.value.trim() === "" ? this.closeComposer() : this.submitComposer(composer, input, { keepGoing: false })
    })
  }

  // Up or Down from an empty new line: close it and edit the line above or below it.
  leaveComposerToward(composer, offset) {
    let neighbor = offset < 0 ? composer.previousElementSibling : composer.nextElementSibling
    if (offset < 0) {
      while (neighbor?.querySelector(":scope > ul > li[data-ticket-id]") && neighbor.offsetParent !== null) {
        neighbor = neighbor.querySelector(":scope > ul").lastElementChild
      }
    }
    const neighborId = neighbor?.dataset?.ticketId
    this.closeComposer()
    if (neighborId) this.startEditById(neighborId)
  }

  // Pasting several lines makes one ticket per line. Leading spaces (two per level) or tabs nest a line under the
  // one above, and list markers ("- ", "* ", "1. ", "- [ ] ") are dropped. A single line pastes as usual.
  pasteLines(pasteEvent, parentId, beforeId) {
    const items = this.parsePastedLines(pasteEvent.clipboardData.getData("text"))
    if (items.length < 2) return
    pasteEvent.preventDefault()
    this.createLines(items, parentId, beforeId)
  }

  pasteIntoNewLine(event) {
    this.pasteLines(event, "", "")
  }

  parsePastedLines(text) {
    return text.split(/\r?\n/).map((line) => {
      const indent = line.match(/^[ \t]*/)[0]
      const columns = [...indent].reduce((count, character) => count + (character === "\t" ? 2 : 1), 0)
      const subject = line.trim().replace(/^(?:[-*+]|\d+[.)])\s+(?:\[[ xX]\]\s+)?/, "")
      return { level: Math.floor(columns / 2), subject }
    }).filter((item) => item.subject !== "")
  }

  async createLines(items, parentId, beforeId) {
    const maximumLines = 100
    if (items.length > maximumLines) return this.showMessage(this.tooManyLinesValue.replace("%{count}", maximumLines))

    const createdIds = []
    for (const item of items) {
      const level = Math.min(item.level, createdIds.length)
      const params = {
        subject: item.subject,
        parent_id: level === 0 ? parentId : createdIds[level - 1],
        before_id: level === 0 ? beforeId : ""
      }
      if (!(await this.send("POST", this.linesPathValue, params))) break
      createdIds.length = level
      createdIds[level] = this.lastBody.id
    }
    this.closeComposer()
    this.newLineTarget.value = ""
    await this.refresh()
  }

  closeComposer() {
    this.listTarget.querySelector("li.todo-composer")?.remove()
    this.listTarget.querySelectorAll("ul.todo-nested-list:empty").forEach((list) => list.remove())
  }

  nestedListOf(line) {
    let list = line.querySelector(":scope > ul")
    if (!list) {
      list = document.createElement("ul")
      list.className = "todo-list todo-nested-list"
      line.append(list)
    }
    return list
  }

  // Moving the focused input in the page blurs it in some browsers; the flag keeps that from ending the composer.
  moveComposer(composer, input, move) {
    this.movingComposer = true
    move()
    input.focus()
    this.movingComposer = false
  }

  indentComposer(composer, input) {
    const above = composer.previousElementSibling
    if (!above?.dataset.ticketId) return
    this.foldedIds.delete(above.dataset.ticketId)
    this.saveFoldedIds()
    this.applyFolds()
    this.moveComposer(composer, input, () => this.nestedListOf(above).append(composer))
  }

  outdentComposer(composer, input) {
    const parentLine = composer.parentElement.closest("li[data-ticket-id]")
    if (!parentLine) return
    const emptiedList = composer.parentElement
    this.moveComposer(composer, input, () => parentLine.after(composer))
    if (emptiedList.children.length === 0) emptiedList.remove()
  }

  async submitComposer(composer, input, { keepGoing = true } = {}) {
    const subject = input.value.trim()
    if (subject === "") return this.closeComposer()

    if (composer.dataset.submitting) return // Enter and the blur that follows it must not send the line twice

    const parentLine = composer.parentElement.closest("li[data-ticket-id]")
    const nextLine = composer.nextElementSibling
    const params = { subject, parent_id: parentLine?.dataset.ticketId || "", before_id: nextLine?.dataset.ticketId || "" }
    composer.dataset.submitting = "1"
    if (!(await this.send("POST", this.linesPathValue, params))) {
      delete composer.dataset.submitting
      return input.focus()
    }
    const createdId = this.lastBody.id
    await this.refresh()
    if (keepGoing) this.openComposerAfter(this.listTarget.querySelector(`li[data-ticket-id="${createdId}"]`))
  }

  // Redmine's context menu script selects (and highlights) a row on any click inside it. Clicks on the
  // line's own controls are not row selections, so they stop here.
  keepClick(event) {
    event.stopPropagation()
  }

  async toggle(event) {
    const checkbox = event.currentTarget
    const line = checkbox.closest("li")
    line.classList.toggle("todo-line-closed", checkbox.checked) // cross out at once; undone if the server refuses
    const path = `${this.linePath(line.dataset.ticketId)}/close`
    if (!checkbox.checked) {
      let reopened = await this.send("DELETE", path, {}, { quiet: [409] })
      if (reopened === false && this.lastStatus === 409) {
        const message = this.confirmReopenSubtreeValue.replace("%{count}", this.lastBody.closed_descendant_count)
        if (!window.confirm(message)) return this.finishToggle(checkbox, false)
        reopened = await this.send("DELETE", path, { reopen_subtree: "1" })
      }
      return this.finishToggle(checkbox, reopened)
    }

    // The line and the lines below it stay in place, crossed out, until the page is reloaded.
    const closedIds = [line, ...line.querySelectorAll("li[data-ticket-id]")].map((nested) => nested.dataset.ticketId)

    let result = await this.send("POST", path, {}, { quiet: [409] })
    if (result === false && this.lastStatus === 409) {
      const message = this.confirmCloseSubtreeValue.replace("%{count}", this.lastBody.open_descendant_count)
      if (!window.confirm(message)) return this.finishToggle(checkbox, false)
      result = await this.send("POST", path, { close_subtree: "1" })
    }
    this.finishToggle(checkbox, result, closedIds)
  }

  async finishToggle(checkbox, succeeded, closedIds = []) {
    if (succeeded) {
      closedIds.forEach((ticketId) => this.closedThisVisit.add(ticketId))
      await this.refresh()
    } else {
      checkbox.checked = !checkbox.checked
      checkbox.closest("li").classList.toggle("todo-line-closed", checkbox.checked)
    }
  }

// Redmine's tooltip is plain CSS, so it cannot follow the pointer. The line records where the pointer is
// and the stylesheet puts the tooltip just to the right of and below it (to the left near the screen's edge).
placeTip(event) {
  const tooltipWidth = 270
  const line = event.currentTarget
  const box = line.getBoundingClientRect()
  let left = event.clientX - box.left + 16
  if (event.clientX + 16 + tooltipWidth > window.innerWidth) left = event.clientX - box.left - 16 - tooltipWidth
  line.style.setProperty("--tip-left", `${left}px`)
  line.style.setProperty("--tip-top", `${event.clientY - box.top + 14}px`)
}

// Dragging: the upper quarter of a line puts the dragged line before it, the lower quarter after it,
  // the middle makes it a child.
  dragStart(event) {
    this.draggedTicketId = this.ticketIdOf(event.currentTarget)
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.draggedTicketId)
  }

  dragOver(event) {
    if (!this.dropIsAllowed(event.currentTarget)) return
    event.preventDefault()
    this.clearDropMarks()
    event.currentTarget.classList.add(`todo-drop-${this.dropZone(event)}`)
  }

  dragLeave(event) {
    event.currentTarget.classList.remove("todo-drop-before", "todo-drop-after", "todo-drop-child")
  }

  dragEnd() {
    this.clearDropMarks()
  }

  async drop(event) {
    if (!this.dropIsAllowed(event.currentTarget)) return
    event.preventDefault()
    const zone = this.dropZone(event)
    const targetLine = event.currentTarget.closest("li")
    this.clearDropMarks()

    let parentId = targetLine.dataset.parentId
    let beforeId = ""
    if (zone === "child") {
      parentId = targetLine.dataset.ticketId
    } else if (zone === "before") {
      beforeId = targetLine.dataset.ticketId
    } else {
      beforeId = targetLine.nextElementSibling?.dataset.ticketId || ""
    }

    const path = `${this.linePath(this.draggedTicketId)}/move`
    if (await this.send("PATCH", path, { parent_id: parentId || "", before_id: beforeId })) {
      await this.refresh()
    }
  }

  dropIsAllowed(textElement) {
    const draggedLine = this.listTarget.querySelector(`li[data-ticket-id="${this.draggedTicketId}"]`)
    return Boolean(draggedLine) && !draggedLine.contains(textElement)
  }

  dropZone(event) {
    const box = event.currentTarget.getBoundingClientRect()
    const fraction = (event.clientY - box.top) / box.height
    if (fraction < 0.25) return "before"
    if (fraction > 0.75) return "after"
    return "child"
  }

  clearDropMarks() {
    this.listTarget.querySelectorAll(".todo-drop-before, .todo-drop-after, .todo-drop-child")
      .forEach((element) => element.classList.remove("todo-drop-before", "todo-drop-after", "todo-drop-child"))
  }

  ticketIdOf(element) {
    return element.closest("li").dataset.ticketId
  }

  linePath(ticketId) {
    return `${this.linesPathValue}/${ticketId}`
  }

  // Returns true when the server accepted the change; otherwise shows its reason and returns false.
  async send(method, path, params = {}, { quiet = [] } = {}) {
    this.hideMessage()
    try {
      const response = await fetch(path, {
        method,
        credentials: "same-origin",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content || ""
        },
        body: new URLSearchParams(params)
      })
      this.lastStatus = response.status
      this.lastBody = await response.json().catch(() => ({}))
      if (response.ok) return true
      if (!quiet.includes(response.status)) this.showMessage(this.lastBody.error || this.failureValue)
    } catch (error) {
      this.showMessage(this.failureValue)
    }
    return false
  }

  async refresh() {
    const url = new URL(this.pageUrlValue, window.location.origin)
    if (this.closedThisVisit.size > 0) url.searchParams.set("keep", [...this.closedThisVisit].join(","))
    const response = await fetch(url, { credentials: "same-origin" })
    if (!response.ok) return this.showMessage(this.failureValue)
    const page = new DOMParser().parseFromString(await response.text(), "text/html")
    const freshList = page.querySelector("[data-todo-target=list]")
    if (freshList) this.listTarget.replaceChildren(...freshList.childNodes)
    this.applyFolds()
  }

  showMessage(text) {
    this.messageTarget.textContent = text
    this.messageTarget.hidden = false
  }

  hideMessage() {
    this.messageTarget.hidden = true
  }
}

application.register("todo", TodoController)
