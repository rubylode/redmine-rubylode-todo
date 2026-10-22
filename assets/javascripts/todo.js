import { Controller } from "@hotwired/stimulus"
import { application } from "controllers/application"

// The to-do list: every change is one request to the plugin, then the list is fetched again,
// so what is on the page is always what the server stored.
class TodoController extends Controller {
  static targets = ["list", "message", "newLine"]
  static values = { linesPath: String, pageUrl: String, confirmCloseSubtree: String, failure: String }

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
    const subjectElement = event.currentTarget
    const original = subjectElement.textContent
    const input = document.createElement("input")
    input.type = "text"
    input.className = "todo-subject-input"
    input.value = original
    subjectElement.replaceWith(input)
    input.focus()

    let finished = false
    const finish = async (save) => {
      if (finished) return
      finished = true
      const subject = input.value.trim()
      if (save && subject !== "" && subject !== original) {
        if (await this.send("PATCH", this.linePath(this.ticketIdOf(input)), { subject })) {
          await this.refresh()
          return
        }
      }
      input.replaceWith(subjectElement)
    }
    input.addEventListener("keydown", (keyEvent) => {
      if (keyEvent.isComposing) return
      if (keyEvent.key === "Enter") finish(true)
      if (keyEvent.key === "Escape") finish(false)
    })
    input.addEventListener("blur", () => finish(true))
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
      return this.finishToggle(checkbox, await this.send("DELETE", path))
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
