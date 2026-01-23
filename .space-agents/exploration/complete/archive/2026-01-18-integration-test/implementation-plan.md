# Integration Test Implementation Plan

**Mission:** MSN-003-Integration-Test
**Created:** 2026-01-18

## Objectives

| # | Objective | Est. | Status |
|---|-----------|------|--------|
| 1 | Create HTML skeleton | 10 min | pending |
| 2 | Add CSS styling | 10 min | pending |
| 3 | Add JavaScript functionality | 15 min | pending |

## Sequence

```
OBJ-001 (foundation)
    └── OBJ-002 (styling)
        └── OBJ-003 (functionality)
```

All sequential. Each depends on the previous.

---

## Objective 1: Create HTML Skeleton

**Goal:** Create test-frontend/ folder and index.html with todo app structure.

**Files:**
- Create: `test-frontend/index.html`

**Tasks:**

1. Create directory
   ```bash
   mkdir -p test-frontend
   ```

2. Write HTML5 skeleton
   ```html
   <!DOCTYPE html>
   <html lang="en">
   <head>
       <meta charset="UTF-8">
       <meta name="viewport" content="width=device-width, initial-scale=1.0">
       <title>Todo App</title>
       <link rel="stylesheet" href="style.css">
   </head>
   <body>
       <main class="container">
           <h1>Todo List</h1>
           <form id="todo-form">
               <input type="text" id="todo-input" placeholder="Add a new task..." required>
               <button type="submit">Add</button>
           </form>
           <ul id="todo-list"></ul>
       </main>
       <script src="app.js"></script>
   </body>
   </html>
   ```

3. Verify
   ```bash
   open test-frontend/index.html
   ```
   Expected: Browser shows "Todo List" heading, input field, Add button.

4. Commit
   ```bash
   git add test-frontend/index.html && git commit -m "feat(obj-1): add HTML skeleton for todo app"
   ```

---

## Objective 2: Add CSS Styling

**Goal:** Create style.css with clean, functional styling.

**Files:**
- Create: `test-frontend/style.css`

**Tasks:**

1. Write CSS
   ```css
   * {
       margin: 0;
       padding: 0;
       box-sizing: border-box;
   }

   body {
       font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
       background: #f5f5f5;
       min-height: 100vh;
       padding: 2rem;
   }

   .container {
       max-width: 500px;
       margin: 0 auto;
       background: white;
       padding: 2rem;
       border-radius: 8px;
       box-shadow: 0 2px 4px rgba(0,0,0,0.1);
   }

   h1 {
       margin-bottom: 1.5rem;
       color: #333;
   }

   #todo-form {
       display: flex;
       gap: 0.5rem;
       margin-bottom: 1.5rem;
   }

   #todo-input {
       flex: 1;
       padding: 0.75rem;
       border: 1px solid #ddd;
       border-radius: 4px;
       font-size: 1rem;
   }

   button {
       padding: 0.75rem 1.5rem;
       background: #007bff;
       color: white;
       border: none;
       border-radius: 4px;
       cursor: pointer;
       font-size: 1rem;
   }

   button:hover {
       background: #0056b3;
   }

   #todo-list {
       list-style: none;
   }

   .todo-item {
       display: flex;
       align-items: center;
       padding: 0.75rem;
       border-bottom: 1px solid #eee;
       gap: 0.75rem;
   }

   .todo-item.completed span {
       text-decoration: line-through;
       color: #999;
   }

   .todo-item span {
       flex: 1;
   }

   .delete-btn {
       background: #dc3545;
       padding: 0.25rem 0.5rem;
       font-size: 0.875rem;
   }

   .delete-btn:hover {
       background: #c82333;
   }
   ```

2. Verify
   ```bash
   open test-frontend/index.html
   ```
   Expected: Centered white card, styled input and button, clean typography.

3. Commit
   ```bash
   git add test-frontend/style.css && git commit -m "feat(obj-2): add CSS styling for todo app"
   ```

---

## Objective 3: Add JavaScript Functionality

**Goal:** Implement add, complete, and delete functionality.

**Files:**
- Create: `test-frontend/app.js`

**Tasks:**

1. Write JavaScript
   ```javascript
   document.addEventListener('DOMContentLoaded', () => {
       const form = document.getElementById('todo-form');
       const input = document.getElementById('todo-input');
       const list = document.getElementById('todo-list');

       form.addEventListener('submit', (e) => {
           e.preventDefault();
           const text = input.value.trim();
           if (!text) return;

           addTodoToDOM(text);
           input.value = '';
           input.focus();
       });

       function addTodoToDOM(text) {
           const li = document.createElement('li');
           li.className = 'todo-item';

           const checkbox = document.createElement('input');
           checkbox.type = 'checkbox';
           checkbox.addEventListener('change', () => {
               li.classList.toggle('completed', checkbox.checked);
           });

           const span = document.createElement('span');
           span.textContent = text;

           const deleteBtn = document.createElement('button');
           deleteBtn.textContent = 'Delete';
           deleteBtn.className = 'delete-btn';
           deleteBtn.addEventListener('click', () => li.remove());

           li.append(checkbox, span, deleteBtn);
           list.appendChild(li);
       }
   });
   ```

2. Verify
   ```bash
   open test-frontend/index.html
   ```
   Manual checklist:
   - [ ] Type text, click Add - todo appears
   - [ ] Click checkbox - todo gets strikethrough
   - [ ] Click Delete - todo removed
   - [ ] Submit empty - nothing happens

3. Commit
   ```bash
   git add test-frontend/app.js && git commit -m "feat(obj-3): add JavaScript for todo functionality"
   ```

---

## Post-Mission Verification

```sql
SELECT id, title, status FROM objectives
WHERE mission_id = 'MSN-003-Integration-Test'
ORDER BY priority;
```

Expected: All three show `status='complete'`

## Cleanup

After verification, delete the test folder:
```bash
rm -rf test-frontend/
```
