codeunit 50506 "ECL Mapping Helper"
{
    /// <summary>
    /// Get BC Location Code from QuickClaim D1valueCode
    /// </summary>
    procedure GetLocationCode(D1ValueCode: Text[100]): Code[10]
    var
        location: Record Location;
    begin
        if D1ValueCode = '' then exit('');

        // Attempt to find Location by matching D1ValueCode to Location Name
        if location.FindSet() then begin
            repeat
                // Use IndexOf and check if the substring starts at position 0
                if D1ValueCode.IndexOf(location."ECL SERVLOC") = 0 then
                    exit(location.Code); // Exit with the location's Code if a match is found at the beginning
            until location.Next() = 0;
        end
        else
            exit('');
    end;

    /// <summary>
    /// Get BC Activity Code from QuickClaim Program
    /// </summary>
    procedure GetActivityCode(Program: Text[50]): Code[20]
    var
        DimValue: Record "Dimension Value";
    begin
        if Program = '' then exit('');
        // Attempt to find Dimension Value by matching Program to Dimension Value Name
        DimValue.SetRange("Dimension Code", 'ACTIVITY');
        DimValue.SetFilter("ECL Activity", '%1', Program);
        if DimValue.FindFirst() then
            exit(DimValue.Code)
        else
            exit('');
    end;

    /// <summary>
    /// Validate that a Location Code exists in BC
    /// </summary>
    procedure ValidateLocationExists(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        if LocationCode = '' then exit(false);
        exit(Location.Get(LocationCode));
    end;
    /// <summary>
    /// Validate that an Activity Dimension Value exists
    /// </summary>
    procedure ValidateActivityExists(ActivityCode: Code[20]): Boolean
    var
        DimValue: Record "Dimension Value";
    begin
        if ActivityCode = '' then exit(false);
        exit(DimValue.Get('ACTIVITY', ActivityCode));
    end;
    /// <summary>
    /// Validate that a Ratio Dimension Value exists
    /// </summary>
    procedure ValidateRatioExists(RatioCode: Code[20]): Boolean
    var
        DimValue: Record "Dimension Value";
    begin
        if RatioCode = '' then exit(false);
        exit(DimValue.Get('RATIO', RatioCode));
    end;
}
