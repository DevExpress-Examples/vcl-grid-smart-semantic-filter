program SimilaritySearch;

uses
  Vcl.Forms,
  Similarity in 'Similarity.pas' {frmSimilarity},
  BertTokenizer in 'C:\Sources_GIT\Misc\BertTokenizer4D\Src\BertTokenizer\BertTokenizer.pas',
  SimilaritySearch.dxSettings in 'SimilaritySearch.dxSettings.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmSimilarity, frmSimilarity);
  Application.Run;
end.
