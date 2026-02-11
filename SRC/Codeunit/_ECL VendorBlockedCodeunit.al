codeunit 50101 BankAccountVendorBlocker
{

    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", OnAfterInsertEvent, '', false, false)]
    procedure BlockVendorOnBankInsert(var Rec: Record "Vendor Bank Account")
    begin
        BlockVendor(Rec."Vendor No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", OnAfterModifyEvent, '', false, false)]
    procedure BlockVendorOnBankModify(var Rec: Record "Vendor Bank Account")
    begin
        BlockVendor(Rec."Vendor No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", OnAfterDeleteEvent, '', false, false)]
    procedure BlockVendorOnBankDelete(var Rec: Record "Vendor Bank Account")
    begin
        BlockVendor(Rec."Vendor No.");
    end;

    local procedure BlockVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then begin
            Vendor.Blocked := Vendor.Blocked::All;
            Vendor.Modify(true);
        end;
    end;

    // [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnAfterValidateEvent, 'No.', false, false)]
    // local procedure SalesLineNoOnAfterValidate(var Rec: Record "Sales Line")
    // var
    //     Item: Record Item;
    // begin
    //     if Rec.IsTemporary() then
    //         exit;
    //     if not (Rec."Document Type" in [Rec."Document Type"::Order, Rec."Document Type"::Invoice]) then exit;
    //     if Rec.Type <> Rec.Type::Item then exit;
    //     Item.SetRange("No.", Rec."No.");
    //     if Item.FindFirst() then begin
    //         if Item."Sales Blocked" then
    //             Error('The item %1 is blocked for sales.', Rec."No.");
    //     end;
    // end;

    // [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, 'No.', false, false)]
    // local procedure PurchaseLineNoOnAfterValidate(var Rec: Record "Purchase Line")
    // var
    //     Item: Record Item;
    // begin
    //     if Rec.IsTemporary() then
    //         exit;
    //     if not (Rec."Document Type" in [Rec."Document Type"::Order, Rec."Document Type"::Invoice]) then exit;
    //     if Rec.Type <> Rec.Type::Item then exit;
    //     Item.SetRange("No.", Rec."No.");
    //     if Item.FindFirst() then begin
    //         if Item."Purchasing Blocked" then
    //             Error('The item %1 is blocked for Purchase.', Rec."No.");
    //     end;
    // end;
}


