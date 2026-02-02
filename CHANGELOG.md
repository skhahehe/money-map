# Changelog - Version 1.1V

All notable changes to the Money Map application implemented in this session.

## [1.1V] - 2026-02-02

### Added
- **Multi-Currency Support**: 
    - Support for USD, INR, PKR, CNY, EUR, and RUB.
    - Persistent selection in settings.
    - Dynamic currency symbols across all UI screens and PDF reports.
- **Loan Tracking System**:
    - Specialized category for tracking money lent to others.
    - Capture borrower names and expected return dates.
    - Business rules to prevent return dates in the past.
- **Enhanced Calendar Heatmap**:
    - Visualize loan activities: Red for "Loan Taken" and Green for "Loan Return".
    - Corrected visualization for future loan return dates.
- **Transaction Management**:
    - New selection mode in the history screen (tap the left icon).
    - Contextual AppBar actions for **Editing** and **Deleting** transactions.
    - Confirmation dialogs for deletions.
- **Strict Input Validation**:
    - Regular expression validation for amount fields (only numbers and `.` allowed).
    - Real-time error messages and dynamic "Save" button disabling for invalid inputs.

### Changed
- Updated category labels in all lists to show **`Loan (Borrower Name)`** for better identification.
- Force-initialized "Loan" category for all users (new and existing).

### Fixed
- Fixed Dart syntax errors related to dollar sign escaping.
- Fixed "Not a constant expression" build errors in UI widgets.
- Added missing imports in `TransactionOverviewScreen`.
