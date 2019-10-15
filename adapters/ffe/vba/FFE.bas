Attribute VB_Name = "FFE"
' sas-appfitter Flat File Emulation adapter for VBA
' Allows bidirectional communication between SAS and VBA (SAS sees datasets, VBA sees a collection of dictionaries)
' Requires JsonConverter (https://github.com/VBA-tools/VBA-JSON) and referenced Microsoft Scripting Runtime in your VBA project

Option Explicit

' Include trailing slash in path definitions below
Private Const StreamPath = ".\"
Private Const DataStorePath = ".\"
Private Const SASProcessPath = ".\"

Private Const SASExeFile = "C:\Program Files\SASHome\SASFoundation\9.4\sas.exe"
Private Const SASCfgFile = "C:\Program Files\SASHome\SASFoundation\9.4\nls\u8\sasv9.cfg"

Private DataStorePaths As New Scripting.Dictionary

Public Const SuccessString = "Response Received"
Public Const RefreshPeriodSecs = 1
Public Const TimeoutSecs = 10


Public Sub SetupDatastore(Name As String, Targ As String)
' Name is reference name of datastore in program
' Targ is target table, in this case a json file
    If DataStorePaths.Exists(Name) Then
        Debug.Print "DataStore " & Name & " was replaced"
        DataStorePaths.Remove Name
    End If
    
    DataStorePaths.Add Name, DataStorePath & Targ & ".json"
End Sub

Public Sub TeardownDatastore(Name As String)
    If DataStorePaths.Exists(Name) Then
        DataStorePaths.Remove Name
    End If
End Sub

Public Function GetDatastoreDset(Name As String, Obj As String) As Collection
    If DataStorePaths.Exists(Name) Then
        Dim fso As New FileSystemObject
        Dim JsonTS As TextStream
        Dim JsonText As String
        Dim Parsed As Dictionary
        
        ' Read .json file
        Set JsonTS = fso.OpenTextFile(DataStorePaths(Name), ForReading)
        JsonText = JsonTS.ReadAll
        JsonTS.Close
        
        ' Parse json to Dictionary
        Set Parsed = JsonConverter.ParseJson(JsonText)
        
        If Parsed.Exists(Obj) Then
          Set GetDatastoreDset = Parsed(Obj)
        Else
          MsgBox "There is no existing entry for " & Obj & " in the " & _
            Name & " Datastore."
          Set GetDatastoreDset = New Collection 'return empty Collection
        End If
    Else
        MsgBox "There is no entry for " & Name & " in the list of available Datastores."
        Set GetDatastoreDset = New Collection 'return empty Collection
    End If

End Function


Public Sub SetDatastoreDset(Name As String, Obj As String, InDset As Collection)
    If DataStorePaths.Exists(Name) Then
        'Take InDset and write key-value pairs to JSON with name Obj
        
        'Add new object to the top
        Dim JsonTxt As String
        Dim Item As Variant
        Dim CountItems As Integer
        Dim Key As Variant
        Dim CountKeys As Integer
        Dim fso As New FileSystemObject
        Dim JsonTS As TextStream
        Dim JsonIn As String
        Dim Parsed As Dictionary
        Dim DsObj As Variant
        Dim Json As Object
        Dim oFile As Object
        
        JsonTxt = "{ """ & Obj & """ : ["
        
        CountItems = 0
        
        For Each Item In InDset
            If TypeName(Item) = "Dictionary" Then
            
                CountItems = CountItems + 1
                If CountItems > 1 Then
                    JsonTxt = JsonTxt & ","
                End If
                
                JsonTxt = JsonTxt & "{"
                CountKeys = 0
                
                For Each Key In Item.Keys
                    CountKeys = CountKeys + 1
                    
                    If CountKeys > 1 Then
                        JsonTxt = JsonTxt & ", "
                    End If
                    
                    JsonTxt = JsonTxt & """" & Key & """ : "
                    
                    If TypeName(Item(Key)) = "String" Then
                        JsonTxt = JsonTxt & """" & Item(Key) & """"
                    Else
                        JsonTxt = JsonTxt & Item(Key)
                    End If
                Next Key
            Else
                MsgBox "SetDatastoreDset subroutine expects a collection of dictionaries"
            End If
            
            JsonTxt = JsonTxt & "}"
        Next Item
        
        JsonTxt = JsonTxt & "]"
        
        'Add each other existing object from datastore
        
        Set JsonTS = fso.OpenTextFile(DataStorePaths(Name), ForReading)
        JsonIn = JsonTS.ReadAll
        JsonTS.Close
        Set Parsed = JsonConverter.ParseJson(JsonIn)
        
        For Each DsObj In Parsed.Keys
            If UCase(DsObj) <> UCase(Obj) Then
                JsonTxt = JsonTxt & ", """ & DsObj & """ : ["
                CountItems = 0
                For Each Item In Parsed(DsObj)
                    If TypeName(Item) = "Dictionary" Then
                    
                        CountItems = CountItems + 1
                        If CountItems > 1 Then
                            JsonTxt = JsonTxt & ","
                        End If
                        
                        JsonTxt = JsonTxt & "{"
                        CountKeys = 0
                        
                        For Each Key In Item.Keys
                            CountKeys = CountKeys + 1
                            
                            If CountKeys > 1 Then
                                JsonTxt = JsonTxt & ", "
                            End If
                            
                            JsonTxt = JsonTxt & """" & Key & """ : "
                            
                            If TypeName(Item(Key)) = "String" Then
                                JsonTxt = JsonTxt & """" & Item(Key) & """"
                            Else
                                JsonTxt = JsonTxt & Item(Key)
                            End If
                        Next Key
                    Else
                        MsgBox "SetDatastoreDset subroutine expects a collection of dictionaries (writing from existing datastore content)"
                    End If
            
                    JsonTxt = JsonTxt & "}"
                Next Item
                
                JsonTxt = JsonTxt & "]"
            End If
        Next DsObj
        
        JsonTxt = JsonTxt & "}"
    
        ' Write updated datastore
        Set Json = JsonConverter.ParseJson(JsonTxt)
        Debug.Print JsonConverter.ConvertToJson(Json)
        
        Set oFile = fso.CreateTextFile(DataStorePaths(Name))
        oFile.WriteLine JsonConverter.ConvertToJson(Json)
        oFile.Close
        Set fso = Nothing
        Set oFile = Nothing

    Else
        MsgBox "There is no entry for " & Name & " in the list of available Datastores."
    End If
End Sub

Public Function GetStreamDset(Obj As String) As Collection
'Returns a collection of dictionaries (rows)

    If Len(Obj) > 0 And Len(Dir(StreamPath & "fromsas.json")) <> 0 Then
    
        Dim fso As New FileSystemObject
        Dim JsonTS As TextStream
        Dim JsonText As String
        Dim Parsed As Dictionary
        Dim NewColl As New Collection
        
        ' TODO - If Handle file not existing
        
        ' Read .json file
        Set JsonTS = fso.OpenTextFile(StreamPath & "fromsas.json", ForReading)
        JsonText = JsonTS.ReadAll
        JsonTS.Close
        
        ' Parse json to Dictionary
        Set Parsed = JsonConverter.ParseJson(JsonText)
        
        If Parsed.Exists(Obj) Then
            Select Case TypeName(Parsed(Obj))
                Case "Collection"
                    Set GetStreamDset = Parsed(Obj)
                Case "Dictionary"
                    NewColl.Add Parsed(Obj)
                    Set GetStreamDset = NewColl
                Case Else
                    Set GetStreamDset = NewColl
            End Select
        Else
            Set GetStreamDset = NewColl 'Return an empty object
        End If
    Else
        Set GetStreamDset = NewColl 'Return an empty object
    End If
End Function

Public Sub SetStreamDset(Obj As String, InDset As Collection)
    'Take InDset and write key-value pairs to JSON with name Obj
    Dim JsonTxt As String
    Dim Json As Object
    Dim fso As Object
    Dim oFile As Object
    Dim Item As Variant
    Dim CountItems As Integer
    Dim Key As Variant
    Dim CountKeys As Integer
    
    JsonTxt = "{ """ & Obj & """ : ["
    
    CountItems = 0
    
    For Each Item In InDset
        If TypeName(Item) = "Dictionary" Then
        
            CountItems = CountItems + 1
            If CountItems > 1 Then
                JsonTxt = JsonTxt & ","
            End If
            
            JsonTxt = JsonTxt & "{"
            CountKeys = 0
            
            For Each Key In Item.Keys
                CountKeys = CountKeys + 1
                
                If CountKeys > 1 Then
                    JsonTxt = JsonTxt & ", "
                End If
                
                JsonTxt = JsonTxt & """" & Key & """ : "
                
                If TypeName(Item(Key)) = "String" Then
                    JsonTxt = JsonTxt & """" & Item(Key) & """"
                Else
                    JsonTxt = JsonTxt & Item(Key)
                End If
            Next Key
        Else
            MsgBox "SetStreamDset subroutine expects a collection of dictionaries"
        End If
        
        JsonTxt = JsonTxt & "}"
    Next Item
    
    JsonTxt = JsonTxt & "]}"
    
    Set Json = JsonConverter.ParseJson(JsonTxt)
    Debug.Print JsonConverter.ConvertToJson(Json)
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set oFile = fso.CreateTextFile(StreamPath & "tosas.json")
    oFile.WriteLine JsonConverter.ConvertToJson(Json)
    oFile.Close
    Set fso = Nothing
    Set oFile = Nothing

End Sub

Public Function WaitForStreamResponse(SubmitTime As Date) As String
    ' Wait until SAS process returns result (new timestamp on json file)
    ' Return a value only when result found
    Dim Response As String
    Dim TimeOutTime, fso, f
    TimeOutTime = DateAdd("s", TimeoutSecs, Now)
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    Application.Cursor = xlWait
    UserForm1.MousePointer = fmMousePointerHourGlass
    
    If Len(Dir(StreamPath & "fromsas.json")) = 0 Then
        ' File does not exist yet, wait for creation
        Do Until Trim(Response & vbNullString) <> vbNullString Or Now >= TimeOutTime
            Application.Wait DateAdd("s", RefreshPeriodSecs, Now)
            If Len(Dir(StreamPath & "fromsas.json")) <> 0 Then
                Response = SuccessString
            End If
        Loop
    
    Else
        ' File exists, wait for update
        Set f = fso.GetFile(StreamPath & "fromsas.json")
        
        Do Until Trim(Response & vbNullString) <> vbNullString Or Now >= TimeOutTime
            Application.Wait DateAdd("s", RefreshPeriodSecs, Now)
            If f.DateLastModified > SubmitTime Then
                Response = SuccessString
            End If
        Loop
    End If
    
    Application.Cursor = xlDefault
    UserForm1.MousePointer = fmMousePointerDefault
    
    If Trim(Response & vbNullString) = vbNullString Then
        Response = "Timed out waiting for response after " & TimeoutSecs & " seconds"
    End If
    
    WaitForStreamResponse = Response
End Function


Public Sub RunSASProcess(Name As String)
    ' Make batch file .bat in same folder as SAS program
    ' Name should not include .sas file extension
    Dim fso As Object
    Dim oFile As Object
    Dim FullPath As String
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Left(SASProcessPath, 2) = ".\" Then
        FullPath = ThisWorkbook.Path & "\"
    Else
        FullPath = SASProcessPath
    End If
    Set oFile = fso.CreateTextFile(FullPath & "run_" & Name & ".bat")
    oFile.WriteLine " """ & SASExeFile & """ " _
        & " -config """ & SASCfgFile & """ " _
        & "-sysin " & """" & FullPath & Name & ".sas"" " _
        & "-log " & """" & FullPath & Name & ".log"" -nologo"
    oFile.Close
    Set fso = Nothing
    Set oFile = Nothing
    
    ' Run batch file
    Call Shell(SASProcessPath & "run_" & Name & ".bat")
End Sub
    

Public Sub PrintDatastore()
    Debug.Print "Printing"
    Dim Key As Variant
    For Each Key In DataStorePaths.Keys
        Debug.Print Key, DataStorePaths(Key)
    Next Key
End Sub
