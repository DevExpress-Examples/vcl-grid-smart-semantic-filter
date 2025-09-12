unit dxSemanticComparer;

interface

type
  TdxSemanticComparer = class
  private
    class var FInstance: TdxSemanticComparer;
    function GetSimilarityImpl(const AValue1, AValue2: string): Single; virtual; abstract;
  public
    class constructor Create;
    class destructor Destroy;
    class function GetSimilarity(const AValue1, AValue2: string): Single;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  System.IOUtils, System.Math,
  System.Net.HttpClient, System.Net.URLClient,
  System.Generics.Collections,
  BertTokenizer,
  onnxruntime_pas_api, onnxruntime;

type
  TTensorLocal = TORTTensor<Single>;

  TEmbedding = class
  private
    FList: TList<Single>;
    FSumRoot: Single;
    function GetCount: Integer;
    procedure SetCount(const AValue: Integer);
    function GetItem(AIndex: Integer): Single;
    procedure SetItem(AIndex: Integer; const AValue: Single);
    function GetSumOfSquaresRoot: Single;
  protected
    class function Dot(AEmbedding1: TEmbedding; AEmbedding2: TEmbedding): Single;
    property SumOfSquaresRoot: Single read GetSumOfSquaresRoot;
  public
    constructor Create;
    destructor Destroy; override;

    property Count: Integer read GetCount write SetCount;
    property Items[AIndex: Integer]: Single read GetItem write SetItem; default;
  end;

  TdxHuggingFaceModelLoader = class
  private
    FRepositoryName: string;
    FPath: string;
  public
    constructor Create(const ARepositoryName: string; const APath: string);
    procedure DownloadFile(const AFileName: string);
  end;

  TdxOnnxSemanticComparer = class(TdxSemanticComparer)
  private
    const
      cHuggingFaceRepository = 'SmartComponents/bge-micro-v2';
      cHuggingFaceModelFile = 'onnx/model_quantized.onnx';
      cHuggingFaceVocabFile = 'vocab.txt';
  private
    FTokenizer: TBertTokenizer;
    FOnnxSession: TORTSession;
    FDimensions: Integer;
    FEmbeddings: TDictionary<string, TEmbedding>;
    FEmbeddingRWLock: TMultiReadExclusiveWriteSynchronizer;
    function GetTensor(const ATokens: TArray<Integer>): TTensorLocal;
    function GetEmbedding(const ATensor: TTensorLocal): TEmbedding; overload;
    function GetEmbedding(const AStr: string): TEmbedding; overload;
    function CosineSimilarity(const AEmbed1: TEmbedding; const AEmbed2: TEmbedding): Single;

    procedure DownloadHuggingFaceDependencies(out AModelFileName: string; out AVocabFileName: string);
  public
    constructor Create;
    destructor Destroy; override;

    function GetSimilarityImpl(const AValue1, AValue2: string): Single; override;
  end;

function TdxOnnxSemanticComparer.GetEmbedding(const ATensor: TTensorLocal): TEmbedding;
var
  ATensorIdx, I: Integer;
  ATensorShape: TArray<Int64>;
begin
  ATensorShape := ATensor.Shape;

  Result := TEmbedding.Create;
  Result.Count := ATensorShape[0];

  for ATensorIdx := 0 to ATensorShape[1] - 1 do
  begin
    for i := 0 to ATensorShape[0] - 1 do
      Result[i] := Result[i] + ATensor.Index3[i, ATensorIdx, 0];
  end;
end;

function TdxOnnxSemanticComparer.GetEmbedding(const AStr: string): TEmbedding;
var
  ATokens: TArray<Integer>;
begin
  FEmbeddingRWLock.BeginRead;
  try
    FEmbeddings.TryGetValue(AStr, Result);
  finally
    FEmbeddingRWLock.EndRead;
  end;

  if Result = nil then
  begin
    FEmbeddingRWLock.BeginWrite;
    try
      ATokens := FTokenizer.Encode(AStr);
      Result := GetEmbedding(GetTensor(ATokens));
      FEmbeddings.AddOrSetValue(AStr, Result);
    finally
      FEmbeddingRWLock.EndWrite;
    end;
  end;
end;

function TdxOnnxSemanticComparer.GetSimilarityImpl(const AValue1, AValue2: string): Single;
var
  AValue1Embed, AValue2Embed: TEmbedding;
begin
  AValue1Embed := GetEmbedding(AValue1);
  AValue2Embed := GetEmbedding(AValue2);
  Result := CosineSimilarity(AValue1Embed, AValue2Embed);
end;

function TdxOnnxSemanticComparer.GetTensor(const ATokens: TArray<Integer>): TTensorLocal;
var
  I: Integer;
  Input_ids, Attention_mask, Token_type_ids: TOrtTensor<Int64>;
  Inputs, Outputs: TORTNameValueList;
begin
  Input_ids := TOrtTensor<Int64>.Create([Length(ATokens), 1]);
  Attention_mask := TOrtTensor<Int64>.Create([Length(ATokens), 1]);
  Token_type_ids := TOrtTensor<Int64>.Create([Length(ATokens), 1]);

  for I := 0 to Length(ATokens) - 1 do
  begin
    Input_ids.index1[i] := ATokens[i];
    Attention_mask.index1[i] := 1;
  end;

  Inputs['input_ids'] := Input_ids.ToValue;
  inputs['attention_mask'] := Attention_mask.ToValue;
  inputs['token_type_ids'] := Token_type_ids.ToValue;

  Outputs := FOnnxSession.Run(Inputs);

  Result := TTensorLocal.FromValue(Outputs.Values[0]);
end;

// This method computes TensorPrimitives.Dot(x, y) / (T.Sqrt(TensorPrimitives.SumOfSquares(x)) * T.Sqrt(TensorPrimitives.SumOfSquares(y)).
function TdxOnnxSemanticComparer.CosineSimilarity(const AEmbed1, AEmbed2: TEmbedding): Single;
begin
  Result := TEmbedding.Dot(AEmbed1, AEmbed2) / (AEmbed1.SumOfSquaresRoot * AEmbed2.SumOfSquaresRoot);
end;

constructor TdxOnnxSemanticComparer.Create;
var
  AModelFileName, AVocabFileName: string;
begin
  inherited Create;
  DownloadHuggingFaceDependencies(AModelFileName, AVocabFileName);

  FTokenizer := TBertTokenizer.Create;
  FTokenizer.LoadVocabulary(AVocabFileName, true);

  FOnnxSession := TORTSession.Create(AModelFileName);
  FDimensions := FOnnxSession.GetOutputTypeInfo(0).GetTensorTypeAndShapeInfo.GetShape[2];

  FEmbeddings := TDictionary<string, TEmbedding>.Create;
  FEmbeddingRWLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TdxOnnxSemanticComparer.Destroy;
begin
  FTokenizer.Free;
  FEmbeddings.Free;
  FEmbeddingRWLock.Free;
  inherited;
end;

procedure TdxOnnxSemanticComparer.DownloadHuggingFaceDependencies(out AModelFileName, AVocabFileName: string);
var
  ALoader: TdxHuggingFaceModelLoader;
const
  cModelDir = 'model';
begin
  ALoader := TdxHuggingFaceModelLoader.Create(cHuggingFaceRepository, TPath.Combine(TPath.GetAppPath, cModelDir));
  try
    AModelFileName := TPath.Combine(TPath.GetAppPath, cModelDir, cHuggingFaceModelFile);
    if not TFile.Exists(AModelFileName) then
      ALoader.DownloadFile(cHuggingFaceModelFile);
    AVocabFileName := TPath.Combine(TPath.GetAppPath, cModelDir, cHuggingFaceVocabFile);
    if not TFile.Exists(AVocabFileName) then
      ALoader.DownloadFile(cHuggingFaceVocabFile);
  finally
    ALoader.Free;
  end;
end;

{ TdxSemanticComparer }

class constructor TdxSemanticComparer.Create;
begin
  FInstance := TdxOnnxSemanticComparer.Create;
end;

class destructor TdxSemanticComparer.Destroy;
begin
  FInstance.Free;
end;

class function TdxSemanticComparer.GetSimilarity(const AValue1, AValue2: string): Single;
begin
  Result := FInstance.GetSimilarityImpl(AValue1, AValue2);
end;

{ TdxHuggingFaceModelLoader }

constructor TdxHuggingFaceModelLoader.Create(const ARepositoryName, APath: string);
begin
  inherited Create;
  FRepositoryName := ARepositoryName;
  FPath := APath;
end;

procedure TdxHuggingFaceModelLoader.DownloadFile(const AFileName: string);
var
  AUrl: string;
  AResponseStream: TStream;
  AHttpClient: THTTPClient;
  AUserAgent: TNameValuePair;
  AHttpResponse: IHTTPResponse;
const
  cHuggingFaceUrl = 'https://huggingface.co/%s/resolve/main/%s?download=true';
begin
  AUrl := Format(cHuggingFaceUrl, [FRepositoryName, AFileName]);
  ForceDirectories(TPath.Combine(FPath, TPath.GetDirectoryName(AFileName)));
  AResponseStream := TFileStream.Create(TPath.Combine(FPath, AFileName), fmCreate);
  try
    AHttpClient := THTTPClient.Create;
    try
      AUserAgent.Name := 'User-Agent';
      AUserAgent.Value := 'DevExpressSample/Delphi';
      AHttpResponse := AHttpClient.Get(AUrl, AResponseStream, [AUserAgent]);
    finally
      AHttpClient.Free;
    end;
  finally
    AResponseStream.Free;
  end;
end;

{ TEmbedding }

constructor TEmbedding.Create;
begin
  inherited Create;
  FList := TList<Single>.Create;
  FSumRoot := -1;
end;

destructor TEmbedding.Destroy;
begin
  FList.Free;
  inherited;
end;

class function TEmbedding.Dot(AEmbedding1, AEmbedding2: TEmbedding): Single;
var
  I: Integer;
  AList1: TList<Single>;
  AList2: TList<Single>;
begin
  AList1 := AEmbedding1.FList;
  AList2 := AEmbedding2.FList;

  Result := 0;
  for I := 0 to AList1.Count - 1 do
    Result := Result + AList1.List[I] * AList2.List[I];
end;

function TEmbedding.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TEmbedding.GetItem(AIndex: Integer): Single;
begin
  Result := FList[AIndex];
end;

procedure TEmbedding.SetCount(const AValue: Integer);
begin
  FList.Count := AValue;
end;

procedure TEmbedding.SetItem(AIndex: Integer; const AValue: Single);
begin
  FList.Items[AIndex] := AValue;
  FSumRoot := -1;
end;

function TEmbedding.GetSumOfSquaresRoot: Single;
var
  I: Integer;
  ASumOfSquares: Single;
begin
  if FSumRoot < 0 then
  begin
    ASumOfSquares := 0;
    for I := 0 to FList.Count - 1 do
      ASumOfSquares := ASumOfSquares + FList.List[I] * FList.List[I];
    FSumRoot := Sqrt(ASumOfSquares);
  end;
  Result := FSumRoot;
end;

end.
