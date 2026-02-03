pageextension 50100 PurchaseOrderPOExt extends "Purchase Order"
{
    layout
    {
        modify("Buy-from Vendor No.")
        {
            Visible = false;
        }
        addafter("Buy-from Vendor No.")
        {
            field(buyVendor; buyVendor)
            {
                ApplicationArea = all;
                Caption = 'Buy-from Vendor No.';

                trigger OnValidate()
                begin
                    if buyVendor <> '' then
                        Rec.Validate("Buy-from Vendor No.", buyVendor);
                    CurrPage.Update();
                end;

                trigger OnLookup(var Text: Text): Boolean
                var
                    Vendor: Record Vendor;
                    UserSetup: Record "User Setup";
                begin
                    Vendor.Reset();
                    UserSetup.get(UserId);
                    if UserSetup."Purchase Resp. Ctr. Filter" <> '' then begin
                        Vendor.FilterGroup(2);
                        Vendor.SetRange("Responsibility Center", UserSetup."Purchase Resp. Ctr. Filter");
                        Vendor.FilterGroup(0);
                        if Page.RunModal(Page::"Vendor List", Vendor) = Action::Lookupok then begin
                            buyVendor := Vendor."No.";
                            exit(true);
                        end;
                    end else

                        if Page.RunModal(Page::"Vendor List", Vendor) = Action::Lookupok then begin
                            buyVendor := Vendor."No.";
                            Rec.Validate("Buy-from Vendor No.", Vendor."No.");
                            exit(true);
                        end;
                end;
            }
        }
    }


    trigger OnAfterGetCurrRecord()
    begin
        if buyVendor = '' then
            buyVendor := Rec."Buy-from Vendor No.";
    end;

    var
        buyVendor: Code[20];
}
