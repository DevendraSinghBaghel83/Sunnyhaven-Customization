pageextension 50104 SalesLineItemLookupExt extends "Sales Order Subform"
{
    layout
    {
        modify("No.")
        {
            Visible = false;
        }
        addbefore("Item Reference No.")
        {
            field("New No."; Rec."New No.")
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    if Rec."New No." <> '' then
                        Rec.Validate("No.", Rec."New No.");
                    Rec."New No." := Rec."No.";
                end;
            }
        }
    }

}