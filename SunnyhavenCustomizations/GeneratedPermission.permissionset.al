namespace PermissionSet;

permissionset 50100 GeneratedPermission
{
    Assignable = true;
    Permissions = tabledata "ECL Claims Import Batch" = RIMD,
        tabledata "ECL Claims Import Line" = RIMD,
        table "ECL Claims Import Batch" = X,
        table "ECL Claims Import Line" = X,
        report "Remittance Advice-Entries Cust" = X,
        report "Remittance Advice-Journal Cust" = X,
        report "Sales-Credit Memo Custom" = X,
        report "Standard Purchase-Order Custom" = X,
        report "Standard Sales-Invoice Custom" = X,
        codeunit BankAccountVendorBlocker = X,
        codeunit "ECL Claims CSV Import" = X,
        codeunit "ECL Claims Doc Creation" = X,
        codeunit "ECL Claims Validation" = X,
        codeunit "ECL Mapping Helper" = X,
        page "ECL Claims Batch FactBox" = X,
        page "ECL Claims Import Batches" = X,
        page "ECL Claims Import Worksheet" = X;
}