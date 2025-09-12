program SimilaritySearch;

uses
  Vcl.Forms,
  Similarity in 'Similarity.pas' {frmSimilarity},
  dxSemanticComparer in 'dxSemanticComparer.pas',
  SimilaritySearch.dxSettings in 'SimilaritySearch.dxSettings.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmSimilarity, frmSimilarity);
  Application.Run;
end.
