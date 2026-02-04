codeunit 50506 "ECL Mapping Helper"
{
    /// <summary>
    /// Get BC Location Code from QuickClaim D1valueCode
    /// </summary>
    procedure GetLocationCode(D1ValueCode: Text[100]): Code[10]
    var
        location: Record Location;
        DimValue: Record "Dimension Value";
        P: Text;
    begin
        P := UpperCase(DelChr(D1ValueCode, '<>', ' ')); // trim + uppercase
        if P = '' then
            exit('');
        DimValue.Reset();
        if D1ValueCode = '' then exit('');
        DimValue.SetRange("Dimension Code", 'SERVLOC');
        DimValue.SetFilter("ECL Activity", '%1|%2|%3|%4',
            P,            // exact match
            P + '|*',     // starts with P|
            '*|' + P,     // ends with |P
            '*|' + P + '|*'); // in middle |P|
        if DimValue.FindFirst() then begin
            exit(DimValue.Code);
        end;
        Error('No Location found for D1ValueCode %1', D1ValueCode);
    end;

    /// <summary>
    /// Get BC Activity Code from QuickClaim Program
    /// </summary>


    procedure GetActivityCode(Program: Text[50]): Code[20]
    var
        DimValue: Record "Dimension Value";
        P: Text;
    begin
        P := UpperCase(DelChr(Program, '<>', ' ')); // trim + uppercase
        if P = '' then
            exit('');

        DimValue.Reset();
        DimValue.SetRange("Dimension Code", 'ACTIVITY');

        // Works for: ECL Activity = CPP|CAS and input Program = CPP or CAS
        DimValue.SetFilter("ECL Activity", '%1|%2|%3|%4',
            P,            // exact match
            P + '|*',     // starts with P|
            '*|' + P,     // ends with |P
            '*|' + P + '|*'); // in middle |P|

        if DimValue.FindFirst() then
            exit(DimValue.Code);

        Error('No Activity found for Program %1', Program);
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
