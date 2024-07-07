pageextension 50100 CollectingErrorsExt extends "Customer List"
{
    actions
    {
        addfirst(processing)
        {
            // This action doesn't collect errors. Any procedure will stop on the first error that occurs,
            // and return the error.
            action(Post)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    i: Record Integer;
                begin
                    i.Number := -9;
                    Codeunit.Run(Codeunit::DoPost, i);
                end;
            }

            // This action collects errors. The PostWithErrorCollect procedure continues on errors,
            // and displays the errors in a dialog to the user done.
            action(PostWithErrorCollect)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    PostWithErrorCollect();
                end;
            }

            // This action collects errors. The PostWithErrorCollectCustomUI procedure continues on errors,
            // and displays error details in a list page when done.
            // This implementation illustrates how you could design your own UI for displaying and
            // troubleshooting errors.
            action(PostWithErrorCollectCustomUI)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    PostWithErrorCollectCustomUI();
                end;
            }
        }
    }

    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure PostWithErrorCollect()
    var
        i: Record Integer;
    begin
        i.Number := -9;
        Codeunit.Run(Codeunit::DoPost, i);
        // After executing the codeunit, there will be collected errors,
        // and therefore an error dialog will be shown when exiting this procedure.
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure PostWithErrorCollectCustomUI()
    var
        errors: Record "Error Message" temporary;
        error: ErrorInfo;
        i: Record Integer;
    begin
        i.Number := -9;
        // By using Codeunit.Run, you ensure any changes to the database within
        // Codeunit::DoPost are rolled back in case of errors.
        if not Codeunit.Run(Codeunit::DoPost, i) then begin
            // If Codeunit.Run fails, a non-collectible error was encountered,
            // add this to the list of errors.
            errors.ID := errors.ID + 1;
            errors.Description := GetLastErrorText();
            errors.Insert();
        end;

        // If there are collected errors, iterate through each of them and
        // add them to "Error Message" record.
        if HasCollectedErrors then
            foreach error in system.GetCollectedErrors() do begin
                errors.ID := errors.ID + 1;
                errors.Description := error.Message;
                errors.Validate("Record ID", error.RecordId);
                errors.Insert();
            end;

        // Clearing the collected errors will ensure the built-in error dialog
        // will not show, but instead show our own custom "Error Messages" page.
        ClearCollectedErrors();

        page.RunModal(page::"Error Messages", errors);
    end;
}


codeunit 50100 DoPost
{
    TableNo = Integer;

    Var
        Number: Integer;

    trigger OnRun()
    begin
        if Number mod 2 <> 0 then
            Error(ErrorInfo.Create('Number should be equal', true, Rec, Rec.FieldNo(Number)));

        if Number <= 0 then
            Error(ErrorInfo.Create('Number should be larger than 0', true, Rec, Rec.FieldNo(Number)));

        if Number mod 3 = 0 then
            Error(ErrorInfo.Create('Number should not be divisible by 10', true, Rec, Rec.FieldNo(Number)));

        // Everything was valid, do the actual posting.
    end;
}
