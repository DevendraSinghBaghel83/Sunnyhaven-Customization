tableextension 50106 PurchaseLineTabExt extends "Purchase Line"
{
    fields
    {
        field(50135; "New No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            ValidateTableRelation = false;
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account"), "System-Created Entry" = const(false)) "G/L Account"."No." where("Direct Posting" = const(true), "Account Type" = const(Posting), Blocked = const(false))
            else
            if (Type = const("G/L Account"), "System-Created Entry" = const(true)) "G/L Account"."No."
            else
            if (Type = const(Resource)) Resource."No."
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"."No."
            else
            if (Type = const("Charge (Item)")) "Item Charge"."No."
            else
            if (Type = const("Allocation Account")) "Allocation Account"."No."
            else
            if (Type = const(Item)) Item."No." where("Purchasing Blocked" = const(false));

        }

    }
}