# Feature Specification: Personal and Group Budget Management

**Feature Branch**: `001-personal-group-budget`
**Created**: 2026-01-12
**Status**: Draft
**Input**: User description: "Il budget deve funzionare così: il primo è quello personale, mi viene chiesto più o meno quanto quante sono le entrate mensili e vengono registrate si parte dal di lì se sono in un gruppo o quando vengo aggiunto un gruppo mi vengono assegnate delle spese si viene a creare la categoria del budget personale spese gruppo, quindi io mi troverò con un massimale di spesa, la procedura guidata dovrà chiedere qual è il mio obiettivo di risparmio mensile e quando mi chiede le entrate mi deve dare la possibilità di mettere stipendio o quale altro tipo di entrata"

## Clarifications

### Session 2026-01-12

- Q: How should the system handle when a user's savings goal is greater than or equal to their total monthly income? → A: Prevent it - Show an error message and require savings goal to be less than total income
- Q: Should the system allow users to enter zero or negative values for income amounts? → A: Allow zero only - Permit zero income but prevent negative values
- Q: What should happen when the total group expenses assigned to a user are greater than their available personal budget (income minus savings)? → A: Auto-adjust savings - Automatically reduce the user's savings goal to accommodate the group expenses and display a notification with the new savings amount
- Q: What should happen to the user's personal budget when they are removed from a group? → A: Keep the group expenses assigned, but remove all the group view and feature - User retains their assigned group expenses (maintaining budget impact) but loses access to group-related views and collaboration features
- Q: Can a user complete the budget setup without adding at least one income source? → A: Allow empty budget - Permit completing setup with no income sources, treating total income as zero

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Personal Budget Initial Setup (Priority: P1)

A user opens the app for the first time and needs to set up their personal budget. The system guides them through a step-by-step process to capture their monthly income sources and savings goals, establishing the foundation for all budget tracking.

**Why this priority**: This is the entry point for all users and the foundational data required before any other budgeting features can work. Without this, no other functionality is possible.

**Independent Test**: Can be fully tested by completing the guided setup flow with at least one income source and a savings goal. Delivers immediate value by showing the user their available budget after savings.

**Acceptance Scenarios**:

1. **Given** a new user opens the app, **When** they start the budget setup, **Then** the system presents a guided procedure asking for monthly income information
2. **Given** the user is entering income, **When** they select an income type, **Then** they can choose from predefined types (Stipendio/Salary, or other custom income types)
3. **Given** the user has entered their income, **When** the system asks for savings goal, **Then** the user can specify their desired monthly savings amount
4. **Given** the user completes the setup, **When** they finish, **Then** their personal budget is created showing total income, savings goal, and available spending amount

---

### User Story 2 - Multiple Income Source Management (Priority: P2)

A user may have multiple sources of income (salary, freelance work, investments, etc.) and needs to track them separately while seeing the total monthly income. The system allows adding multiple income entries with different types and amounts.

**Why this priority**: Many users have multiple income streams, and accurate budget planning requires capturing all sources. This enhances the P1 setup experience but isn't critical for basic functionality.

**Independent Test**: Can be tested by adding 2-3 different income sources with different types and amounts, then verifying the total is correctly calculated and displayed.

**Acceptance Scenarios**:

1. **Given** a user is in the income setup step, **When** they add their first income source, **Then** they can add additional income sources
2. **Given** multiple income sources exist, **When** viewing the budget summary, **Then** the system displays each income source separately and shows the total monthly income
3. **Given** a user has set up income sources, **When** they want to modify them later, **Then** they can edit or remove existing income sources

---

### User Story 3 - Group Membership and Expense Assignment (Priority: P3)

When a user joins or is added to a family/group budget, they receive expense assignments from the group. These group expenses create a new budget category in their personal budget called "Group Expenses" with a spending limit that affects their available personal budget.

**Why this priority**: This enables collaborative family budget management but depends on having a personal budget first (P1). It's valuable for families but not required for individual users.

**Independent Test**: Can be tested by having one user invite another to a group, assigning expenses to the new member, and verifying the "Group Expenses" category appears in their personal budget with the correct spending limit.

**Acceptance Scenarios**:

1. **Given** a user with an existing personal budget, **When** they are added to a group, **Then** a new "Group Expenses" category is created in their personal budget
2. **Given** a user is a group member, **When** expenses are assigned to them by the group, **Then** these expenses appear under their "Group Expenses" category with a total spending limit
3. **Given** a user has group expenses assigned, **When** they view their personal budget, **Then** the spending limit for group expenses is deducted from their available personal budget
4. **Given** group expense assignments change, **When** expenses are added or removed, **Then** the user's spending limit updates accordingly in real-time
5. **Given** a user has a personal budget with a savings goal, **When** group expenses are assigned that exceed their available budget (income minus savings), **Then** the system automatically reduces their savings goal to accommodate the group expenses and displays a notification with the new savings amount

---

### Edge Cases

- **Savings goal exceeds income**: System prevents users from entering a savings goal that is greater than or equal to their total income. An error message is displayed requiring the savings goal to be less than total income.
- **Zero or negative income**: System allows zero income values but prevents negative income amounts. An error message is displayed if a negative value is entered.
- **Group expenses exceed available budget**: When group expenses assigned to a user exceed their available personal budget (income minus savings), the system automatically reduces the user's savings goal to accommodate the group expenses and displays a notification showing the new savings amount.
- **User removed from group**: When a user is removed from a group, they retain their assigned group expenses (the "Group Expenses" category remains with current spending limit), but lose access to all group-related views and collaboration features. The expenses continue to impact their personal budget.
- **Budget setup with no income sources**: Users can complete the budget setup without adding any income sources. The system treats total income as zero and allows proceeding to savings goal entry.
- How does the system handle income types in different languages or currencies?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a guided setup procedure for first-time users to create their personal budget
- **FR-002**: System MUST allow users to enter their monthly income amount
- **FR-003**: System MUST validate that income amounts are greater than or equal to zero and display an error message if a negative value is entered
- **FR-004**: System MUST provide predefined income types including "Stipendio" (Salary) and allow users to specify other custom income types
- **FR-005**: System MUST allow users to add multiple income sources with different types and amounts
- **FR-006**: System MUST ask users to specify their monthly savings goal during setup
- **FR-007**: System MUST validate that the savings goal is less than the total income and display an error message if the validation fails
- **FR-008**: System MUST calculate available spending budget as (Total Income - Savings Goal)
- **FR-009**: System MUST allow users to join or be added to a group budget
- **FR-010**: System MUST create a "Group Expenses" category in a user's personal budget when they join a group
- **FR-011**: System MUST allow group expenses to be assigned to individual group members
- **FR-012**: System MUST display a spending limit for group expenses assigned to a user
- **FR-013**: System MUST deduct the group expense spending limit from the user's available personal budget
- **FR-014**: System MUST update the user's group expense spending limit when assignments change
- **FR-015**: System MUST automatically reduce the user's savings goal when group expenses exceed available budget (income minus savings) to accommodate the group expenses
- **FR-016**: System MUST display a notification to the user showing the new adjusted savings amount when their savings goal is automatically reduced due to group expense assignment
- **FR-017**: System MUST persist all budget data (income sources, savings goals, group assignments) for future sessions
- **FR-018**: System MUST display the total monthly income across all sources
- **FR-019**: System MUST allow users to edit or remove existing income sources after initial setup
- **FR-020**: When a user is removed from a group, system MUST retain the user's "Group Expenses" category with the current spending limit and continue deducting it from their available budget
- **FR-021**: When a user is removed from a group, system MUST remove access to all group-related views and collaboration features while maintaining the group expense assignments
- **FR-022**: System MUST allow users to complete budget setup without adding any income sources, treating total income as zero

### Key Entities

- **Personal Budget**: Represents an individual user's budget with total income, savings goal, and available spending amount. Contains multiple income sources and may include a group expense category.
- **Income Source**: Represents a single source of income with a type (Salary, Freelance, Investment, Other) and monthly amount. Multiple income sources belong to one personal budget.
- **Savings Goal**: Monthly savings target amount set by the user, deducted from total income to calculate available spending.
- **Group Budget**: Represents a shared budget for a family or group, containing multiple members and expense assignments.
- **Group Expense Assignment**: Links specific expenses from a group budget to individual members with spending limits. Creates a category in the member's personal budget.
- **Group Expenses Category**: A special budget category created in a user's personal budget when they join a group, showing their assigned expenses and spending limit.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete the initial personal budget setup (income entry and savings goal) in under 3 minutes
- **SC-002**: 95% of users successfully add at least one income source during setup without errors
- **SC-003**: Users can add multiple income sources and see the correct total calculation displayed within 1 second
- **SC-004**: When a user joins a group, their "Group Expenses" category appears in their personal budget within 2 seconds
- **SC-005**: Group expense assignments reflect in a member's personal budget spending limit with no more than 5 seconds delay
- **SC-006**: Users understand their available budget (income minus savings and group expenses) clearly, with 90% able to explain it when asked
- **SC-007**: The guided setup procedure has a completion rate of at least 85% (users who start finish the setup)
- **SC-008**: Budget calculations remain accurate across all scenarios (verified through automated testing)

## Assumptions

- **A-001**: Users understand basic budgeting concepts (income, expenses, savings)
- **A-002**: All monetary values are in the same currency for a given user's budget
- **A-003**: Income amounts are monthly recurring amounts (not one-time payments)
- **A-004**: Group membership is managed separately (invitation/acceptance flow is outside this feature's scope)
- **A-005**: The guided setup is mandatory for first-time users before accessing other app features
- **A-006**: Users can only belong to one group at a time (or if multiple groups are allowed, each creates a separate category)
- **A-007**: Income type list can be localized based on user's language preference
- **A-008**: Savings goal is optional - users can enter zero if they don't want to save
- **A-009**: Users can complete budget setup with zero income sources (total income treated as zero)

## Out of Scope

- Actual expense tracking or categorization (beyond group expense limits)
- Bill payment functionality
- Financial account integration or bank syncing
- Budget recommendations or AI-powered suggestions
- Historical budget analysis or reporting
- Budget sharing with non-group members
- Multiple currency support within a single budget
- Investment tracking or portfolio management
- Debt management features
- Tax calculation or reporting
