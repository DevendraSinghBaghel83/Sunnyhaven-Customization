pageextension 50106 SalesLinePageExt extends "Sales Invoice Subform"
{
    layout
    {
        // modify("No.")
        // {
        //     Visible = true;
        // }
        // addbefore("Item Reference No.")
        // {
        //     field("New No."; Rec."New No.")
        //     {
        //         ApplicationArea = All;

        //         trigger OnValidate()
        //         begin
        //             if Rec."New No." <> '' then
        //                 Rec.Validate("No.", Rec."New No.");
        //             Rec."New No." := Rec."No.";
        //         end;
        //     }
        // }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}