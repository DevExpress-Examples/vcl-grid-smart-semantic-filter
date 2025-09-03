unit Similarity;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit,
  cxLabel, cxTextEdit,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, Data.DB, cxDBData, dxmdaset, cxGridLevel, cxClasses, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxTrackBar, cxCheckBox, cxGroupBox, dxFormattedLabel, cxButtons;

type
  TfrmSimilarity = class(TForm)
    GridDBTableView1: TcxGridDBTableView;
    GridLevel1: TcxGridLevel;
    Grid: TcxGrid;
    MemData: TdxMemData;
    MemDataId: TIntegerField;
    MemDataName: TStringField;
    MemDataDescription: TStringField;
    DataSource: TDataSource;
    Name: TcxGridDBColumn;
    Description: TcxGridDBColumn;
    Id: TcxGridDBColumn;
    lblFilter: TcxLabel;
    txtFilter: TcxTextEdit;
    grpSettings: TcxGroupBox;
    trackSimilarity: TcxTrackBar;
    chkFilterByDesc: TcxCheckBox;
    lblDescription: TdxFormattedLabel;
    lblSimilarity: TcxLabel;
    btnFilter: TcxButton;
    procedure btnFilterClick(Sender: TObject);
    procedure trackSimilarityPropertiesGetTickLabel(Sender: TObject; const APosition: Integer; var AText: string);
    procedure GridDBTableView1DataControllerFilterRecord(ADataController: TcxCustomDataController;
      ARecordIndex: Integer; var Accept: Boolean);
  private
    function GetFilter: string;
    function GetSimilarity: Single;
    function GetFilterByDesc: Boolean;
  public
    property Similarity: Single read GetSimilarity;
    property FilterByDesc: Boolean read GetFilterByDesc;
  end;

var
  frmSimilarity: TfrmSimilarity;

implementation

uses
  dxSemanticComparer;


{$R *.dfm}

function TfrmSimilarity.GetFilter: string;
begin
  Result := txtFilter.Text;
end;

function TfrmSimilarity.GetFilterByDesc: Boolean;
begin
  Result := chkFilterByDesc.Checked;
end;

function TfrmSimilarity.GetSimilarity: Single;
begin
  Result := trackSimilarity.Position / 100;
end;

procedure TfrmSimilarity.GridDBTableView1DataControllerFilterRecord(ADataController: TcxCustomDataController;
  ARecordIndex: Integer; var Accept: Boolean);
begin
  Accept := GetFilter = '';
  if not Accept then
    Accept := TdxSemanticComparer.GetSimilarity(GetFilter, ADataController.Values[ARecordIndex, Name.Index]) >= Similarity;
  if not Accept and GetFilterByDesc then
    Accept := TdxSemanticComparer.GetSimilarity(GetFilter, ADataController.Values[ARecordIndex, Description.Index]) >= Similarity;
end;

procedure TfrmSimilarity.btnFilterClick(Sender: TObject);
begin
  GridDBTableView1.DataController.Refresh;
end;

procedure TfrmSimilarity.trackSimilarityPropertiesGetTickLabel(Sender: TObject; const APosition: Integer;
  var AText: string);
begin
  AText := (APosition / 100).ToString;
end;

end.

