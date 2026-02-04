pageextension 50505 VendorListExt extends "Vendor List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
    }
    trigger OnOpenPage()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId) then begin
            if UserSetup."Purchase Resp. Ctr. Filter" <> '' then
                Rec.SetFilter(
                    "Responsibility Center",
                    UserSetup."Purchase Resp. Ctr. Filter");
        end;
    end;


    var
        myInt: Integer;
}