VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} UserForm1 
   Caption         =   "UserForm1"
   ClientHeight    =   5025
   ClientLeft      =   90
   ClientTop       =   405
   ClientWidth     =   6300
   OleObjectBlob   =   "UserForm1.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "UserForm1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub DebugButton_Click()
    Call Refresh
End Sub

Private Sub FavBox_Click()
  SelectY.Value = Split(FavBox.Value)(0)
  SelectX.Value = Split(FavBox.Value)(2)
End Sub

Private Sub RefreshStream()
    Dim MyData As Collection
    Dim PlotPath As String
    Dim Row As Variant
    
    Set MyData = GetStreamDset("MYDATA")
    
    For Each Row In MyData
        PlotPath = Row("plotpath")
        If Len(Dir(PlotPath)) = 0 Then
            MsgBox "Image not found " & PlotPath
        Else
            Debug.Print "Loading Picture " & PlotPath
            PlotArea.Picture = LoadPicture(PlotPath)
        End If
    Next Row
    
    Debug.Print MyData.Count & " Values Found"
End Sub

Private Sub RefreshFavs()
    Dim Favourites As Collection
    Set Favourites = GetDatastoreDset("MyStoredData", "FAVOURITES")
    
    FavBox.Clear

    For Each Row In Favourites
       FavBox.AddItem StrConv(Row("yaxis"), vbProperCase) & " vs " & StrConv(Row("xaxis"), vbProperCase)
    Next Row
End Sub

Public Sub Refresh()
    Call RefreshStream
    Call RefreshFavs
End Sub


Private Sub RunButton_Click()
    Dim Response As String
    Dim Parms As New Dictionary
    Dim Dset As New Collection
    Dim SubmitTime As Date
    
    Parms("xaxis") = SelectX.Value
    Parms("yaxis") = SelectY.Value
    Dset.Add Parms
    
    Call SetStreamDset("MYDATA", Dset)
    
    SubmitTime = Now
    
    Call RunSASProcess("genericprogram")
    
    Response = WaitForStreamResponse(SubmitTime)
    
    MsgBox Response
    
    If StrComp("response received", Response, vbTextCompare) = 0 Then
        MsgBox "Refreshing"
        Call Refresh
    End If
End Sub

Private Sub SelectX_Change()
End Sub

Private Sub SelectY_Change()
End Sub


Private Sub UserForm_Initialize()
    On Error GoTo ErrorHandle
    
    ChDir ThisWorkbook.Path
    
    Call SetupDatastore("MyStoredData", "appconfig")

    SelectX.List = Array("Name", "Sex", "Age", "Height", "Weight")
    SelectY.List = Array("Name", "Sex", "Age", "Height", "Weight")
    
    Call RefreshFavs
        
    Exit Sub
ErrorHandle:
        MsgBox Err.Description
End Sub


Private Sub UserForm_Terminate()
    Call TeardownDatastore("MyStoredData")
End Sub

