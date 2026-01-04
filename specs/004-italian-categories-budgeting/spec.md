# Feature Specification: Italian Categories and Budget Management System

**Feature Branch**: `004-italian-categories-budgeting`
**Created**: 2026-01-04
**Status**: Draft
**Input**: User description: "vorrei modificare il sistema delle categorie e del budgeting: 1 - le categorie sono in italiano ; 2 da impostazioni posso impostare le categorie di default e un budget specifico per quelle categorie. ad ogni acquisto  in una categorie vergine ( non ancora usata) , il sistema mi chiede se voglio impostare un budget per quella categoria, in alternativa, viene usato il budget di una categria generica ( varie o altro , decidi tu). 3 nella dashboard voglio vedere la situazione dei singoli sottobudget e del budget generale e, per ogni spesa, nella parte  inferiore della schermata dei dettagli, dammi una panoramica dello stato del budget ( o qualche informazione che contestualizza quella spesa nel budget."

## Clarifications

### Session 2026-01-04

- Q: The spec describes budget amounts but doesn't specify the time period those budgets cover. What budget period should the system use? → A: Monthly budgets (reset each month, most common for family budgeting)
- Q: The spec introduces Italian categories and budget management, but doesn't clarify how this relates to any existing category system. Should the system migrate existing data or start fresh? → A: Replace entirely: Delete old categories, orphan existing expenses (require re-categorization)
- Q: The spec mentions "overall budget summary" in the dashboard, but doesn't clarify how the overall budget is defined. How should it be calculated? → A: Sum of all category budgets (automatic calculation, no separate input)
- Q: The spec requires Italian categories but doesn't specify which categories should be provided by default. What should users see initially? → A: Common Italian household categories (Spesa, Benzina, Ristoranti, Bollette, Salute, etc.) pre-populated
- Q: The spec describes prompting users when they use a "virgin category" for the first time, but doesn't clarify what defines "first-time use" - is it per-user or system-wide? → A: Per-user tracking: Each family member gets prompted independently for their first use

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Italian Category Names (Priority: P1)

Users need to see and interact with expense categories in Italian language to make the application feel natural and accessible for Italian-speaking family members.

**Why this priority**: Language localization is foundational - all subsequent features depend on Italian category names. Without this, the Italian-speaking users will struggle with the application.

**Independent Test**: Can be fully tested by viewing the category list in settings and during expense creation, confirming all categories display in Italian and delivers immediate usability improvement for Italian users.

**Acceptance Scenarios**:

1. **Given** the user opens the settings page for the first time after migration, **When** viewing the category list, **Then** a pre-populated set of common Italian categories is displayed (Spesa, Benzina, Ristoranti, Bollette, Salute, Trasporti, Casa, Svago, Abbigliamento, Varie)
2. **Given** the user creates a new expense, **When** selecting a category, **Then** the category picker shows Italian category names
3. **Given** the user views existing expenses, **When** looking at expense details, **Then** the category name is shown in Italian

---

### User Story 2 - Default Categories with Budgets (Priority: P2)

Users want to set up their financial planning upfront by configuring default categories with specific budget amounts in the settings, creating a personalized budgeting framework before tracking expenses.

**Why this priority**: This enables proactive budget planning and establishes the foundation for budget tracking. Users can set their financial goals before starting to track expenses.

**Independent Test**: Can be fully tested by navigating to settings, creating/editing default categories with budget amounts, and verifying the budgets are stored and displayed correctly.

**Acceptance Scenarios**:

1. **Given** the user is in settings, **When** they create a new default category with a budget amount, **Then** the category and budget are saved and displayed in the category list
2. **Given** the user has default categories configured, **When** they edit a category's budget amount, **Then** the updated budget is saved and reflected in the dashboard
3. **Given** the user creates a default category without specifying a budget, **When** viewing the category list, **Then** the category is listed with no budget assigned
4. **Given** the user deletes a default category, **When** confirming the deletion, **Then** the category and its budget are removed from the system

---

### User Story 3 - Budget Prompt for First-Time Category Use (Priority: P3)

When users record an expense in a category they haven't used before (virgin category), the system proactively asks if they want to set a budget for that category, helping users build their budgeting structure organically as they spend.

**Why this priority**: This provides a just-in-time budgeting approach that adapts to actual spending patterns, but it's not critical for basic functionality - users can still track expenses without it.

**Independent Test**: Can be fully tested by creating an expense in a previously unused category, verifying the budget prompt appears, and confirming the user's choice (set budget or use default) is properly applied.

**Acceptance Scenarios**:

1. **Given** the user creates an expense in a category they have never used before (virgin for this user), **When** saving the expense, **Then** a prompt appears asking if they want to set a budget for this category
2. **Given** the budget prompt is displayed, **When** the user chooses to set a budget and enters an amount, **Then** the budget is saved and applied to that category
3. **Given** the budget prompt is displayed, **When** the user declines to set a budget, **Then** the expense uses the generic "Varie" category budget
4. **Given** the user has previously used a category, **When** creating another expense in that category, **Then** no prompt appears and the existing budget is used
5. **Given** another family member has already used a category, **When** a different user creates their first expense in that same category, **Then** the prompt still appears for the new user (per-user tracking)

---

### User Story 4 - Dashboard Budget Overview (Priority: P2)

Users want to see a comprehensive view of their financial health by monitoring individual category budgets and the overall budget situation directly on the dashboard.

**Why this priority**: This provides essential budget monitoring capability and immediate feedback on spending patterns. It's the primary interface for budget awareness.

**Independent Test**: Can be fully tested by creating categories with budgets, adding expenses, and verifying the dashboard displays current status for each category budget and overall budget totals.

**Acceptance Scenarios**:

1. **Given** the user has categories with budgets, **When** viewing the dashboard, **Then** each category shows current spending vs. budget amount
2. **Given** the user has multiple category budgets, **When** viewing the dashboard, **Then** an overall budget summary shows the automatically calculated total (sum of all category budgets) and total spending
3. **Given** a category budget is exceeded, **When** viewing the dashboard, **Then** that category is visually highlighted or marked as over-budget
4. **Given** the user has no expenses yet, **When** viewing the dashboard, **Then** budget widgets show 0% utilization for each category
5. **Given** the user adds a new category with a budget, **When** viewing the dashboard, **Then** the overall budget total automatically increases by the new category's budget amount

---

### User Story 5 - Expense Detail Budget Context (Priority: P3)

When viewing an individual expense, users want to understand how that expense impacts their budget by seeing relevant budget information in the lower section of the expense detail screen.

**Why this priority**: This provides contextual budget awareness at the transaction level, helping users understand the impact of individual purchases. It's valuable but not essential for basic budget tracking.

**Independent Test**: Can be fully tested by opening any expense detail screen and verifying that budget context information (category budget status, remaining budget, percentage used) is displayed in the lower section.

**Acceptance Scenarios**:

1. **Given** the user views an expense detail, **When** scrolling to the bottom of the screen, **Then** budget status information for that expense's category is displayed
2. **Given** an expense belongs to a budgeted category, **When** viewing the expense detail, **Then** the budget context shows remaining budget amount and percentage used
3. **Given** an expense uses the generic "Varie" budget, **When** viewing the expense detail, **Then** the budget context indicates it's using the generic budget with its status
4. **Given** the category budget was exceeded by this expense, **When** viewing the expense detail, **Then** the budget context highlights that the budget was exceeded

---

### Edge Cases

- What happens when a user creates an expense in a virgin category but the generic "Varie" category budget doesn't exist?
- How does the system handle a user changing an expense's category from one with a budget to one without?
- What happens if a user deletes a default category that has existing expenses associated with it? (Expenses become orphaned and require re-categorization)
- What happens when a user edits an expense amount that changes the budget status from under-budget to over-budget?
- How does the system handle budget calculations when expenses are deleted?
- What happens to orphaned expenses during budget calculations - are they excluded or counted under "Varie"?
- How should the system handle bulk re-categorization of multiple orphaned expenses?
- What happens if a user has hundreds of orphaned expenses - is there a bulk action available?
- When a category budget is deleted, how does the overall budget total update?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display all expense categories in Italian language throughout the application
- **FR-002**: System MUST provide a settings interface for creating and managing default categories
- **FR-003**: Users MUST be able to assign a specific monthly budget amount to each default category
- **FR-004**: System MUST allow users to create categories without assigning a budget amount
- **FR-005**: System MUST maintain a generic fallback category called "Varie" (or similar) with its own budget
- **FR-006**: System MUST track category usage on a per-user basis to detect when a specific user creates an expense in a category they haven't used before (virgin category for that user)
- **FR-007**: System MUST prompt each user individually to set a budget when they use a virgin category for the first time (even if other family members have already used that category)
- **FR-008**: System MUST allow users to decline setting a budget for a virgin category
- **FR-009**: System MUST automatically apply the generic "Varie" budget when user declines to set a category budget
- **FR-010**: System MUST display individual category budget status on the dashboard
- **FR-011**: System MUST calculate and display current spending amount for each budgeted category
- **FR-012**: System MUST calculate and display remaining budget amount for each budgeted category
- **FR-013**: System MUST calculate and display percentage of budget used for each budgeted category
- **FR-014**: System MUST calculate overall budget as the sum of all individual category budgets and display it with total spending
- **FR-015**: System MUST visually distinguish categories that have exceeded their budget
- **FR-016**: System MUST display budget context information in the expense detail view
- **FR-017**: System MUST show category budget status, remaining amount, and percentage used in expense details
- **FR-018**: System MUST indicate when an expense is using the generic "Varie" budget
- **FR-019**: System MUST persist category budgets across application restarts
- **FR-020**: System MUST update budget calculations in real-time when expenses are added, edited, or deleted
- **FR-021**: System MUST automatically reset monthly budgets at the beginning of each calendar month
- **FR-022**: System MUST track spending only for the current month when calculating budget utilization
- **FR-023**: System MUST delete all existing (non-Italian) categories when implementing the new Italian category system
- **FR-024**: System MUST mark existing expenses as orphaned (no category) when their categories are deleted
- **FR-025**: System MUST provide a mechanism for users to re-categorize orphaned expenses using the new Italian categories
- **FR-026**: System MUST identify and display orphaned expenses clearly so users can re-categorize them
- **FR-027**: System MUST pre-populate a default set of common Italian household expense categories on initial setup
- **FR-028**: Default categories MUST include at minimum: Spesa (Groceries), Benzina (Fuel), Ristoranti (Restaurants), Bollette (Bills), Salute (Health), Trasporti (Transportation), Casa (Home), Svago (Entertainment), Abbigliamento (Clothing), and Varie (Miscellaneous)
- **FR-029**: Users MUST be able to edit, delete, or add to the default category set
- **FR-030**: Default categories MUST be created without pre-assigned budget amounts (users set budgets as needed)

### Key Entities

- **Categoria (Category)**: Represents an expense category with Italian name, optional monthly budget amount, and per-user usage tracking. Attributes include category name (Italian), monthly budget amount (optional), current month spending, and per-user first-use indicators (tracks which users have/haven't used this category).
- **Budget**: Represents monthly budget allocation with target amount, current spending, and status. Attributes include monthly allocated amount, current month spent amount, remaining amount, percentage used, over-budget indicator, and current month reference.
- **Generic Budget ("Varie")**: Special fallback budget category that applies when users don't assign specific budgets. Has its own monthly budget amount and tracks current month expenses from unbundled categories.
- **User-Category Usage**: Tracks which users have used which categories, enabling per-user virgin category detection. Attributes include user ID, category ID, and first-use timestamp.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view all expense categories in Italian language without seeing any English category names
- **SC-002**: Users can configure at least 10 default categories with individual budget amounts in under 5 minutes
- **SC-003**: When creating an expense in a virgin category, users receive a budget setup prompt within 1 second of saving the expense
- **SC-004**: Dashboard displays budget status for all configured categories with current spending percentages visible at a glance
- **SC-005**: Users can identify over-budget categories immediately upon viewing the dashboard through visual indicators
- **SC-006**: 90% of users successfully understand their budget status within 10 seconds of viewing the dashboard
- **SC-007**: Expense detail view provides budget context that helps users understand the impact of individual expenses on their category budget
- **SC-008**: Budget calculations update within 2 seconds after any expense is added, modified, or deleted
