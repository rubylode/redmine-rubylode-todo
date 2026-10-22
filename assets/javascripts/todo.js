import { Controller } from "@hotwired/stimulus"
import { application } from "controllers/application"

// The to-do list: every change is one request to the plugin, then the list is fetched again,
// so what is on the page is always what the server stored.
class TodoController extends Controller {
  static targets = ["list", "message", "newLine"]
  static values = { linesPath: String, pageUrl: String, confirmCloseSubtree: String, failure: String }

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

  async toggle(event) {
    const checkbox = event.currentTarget
    const path = `${this.linePath(this.ticketIdOf(checkbox))}/close`
    if (!checkbox.checked) {
      return this.finishToggle(checkbox, await this.send("DELETE", path))
    }

    let result = await this.send("POST", path, {}, { quiet: [409] })
    if (result === false && this.lastStatus === 409) {
      const message = this.confirmCloseSubtreeValue.replace("%{count}", this.lastBody.open_descendant_count)
      if (!window.confirm(message)) return this.finishToggle(checkbox, false)
      result = await this.send("POST", path, { close_subtree: "1" })
    }
    this.finishToggle(checkbox, result)
  }

  async finishToggle(checkbox, succeeded) {
    if (succeeded) {
      await this.refresh()
    } else {
      checkbox.checked = !checkbox.checked
    }
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
    const response = await fetch(this.pageUrlValue, { credentials: "same-origin" })
    if (!response.ok) return this.showMessage(this.failureValue)
    const page = new DOMParser().parseFromString(await response.text(), "text/html")
    const freshList = page.querySelector("[data-todo-target=list]")
    if (freshList) this.listTarget.innerHTML = freshList.innerHTML
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
