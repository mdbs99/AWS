{
  MIT License

  Copyright (c) 2013-2019 Marcos Douglas B. Santos

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
}unit aws_ses;

{$i aws.inc}

interface

uses
  //rtl
  classes,
  sysutils,
  //synapse
  synautil,
  synacode,
  //aws
  aws_base,
  aws_client;

type

  teFormato = (teHtml, teTexto);

  ISESObjects = Interface;
  TSESMessage = class;

  ISESRegion = interface(IInterface)
  ['{B72DE2B7-600D-47E1-9CB1-8BE7CBFBB907}']
    function SESObjects: ISESObjects;
  end;

  ISESObject = interface(IInterface)
  ['{CE161E39-4FA9-46C5-B528-268506DC4740}']
    function Name: string;
    function Stream: IAWSStream;
  end;

  ISESObjects = interface(IInterface)
  ['{FF36521F-A15F-4C98-84DB-4669236F37A8}']
    function SendEmail(Message: TSESMessage): IAWSResponse;
  end;

  TSESMessage = class
  private
    FTOName: String;
    FTOAddress: String;
    FFrom: String;
    FSubject: String;
    FFormat: teFormato;
    FCharset: String;
    FMessage: String;
  published
    property TOName: String read FTOName write FTOName;
    property TOAddress: String read FTOAddress write FTOAddress;
    property From: String read FFrom write FFrom;
    property Subject: String read FSubject write FSubject;
    property Format: teFormato read FFormat write FFormat;
    property Charset: String read FCharset write FCharset;
    property Message: String read FMessage write FMessage;
  end;


  { TSESRegion }

  TSESRegion = class sealed(TInterfacedObject, ISESRegion)
  private
    FClient: IAWSClient;
  public
    constructor Create(Client: IAWSClient; sRegion: String);
    class function New(Client: IAWSClient; sRegion: String): ISESRegion;
    function SESObjects: ISESObjects;
  end;

  { TSESObjects }

  TSESObjects = class sealed(TInterfacedObject, ISESObjects)
  private
    FClient: IAWSClient;
  public
    constructor Create(Client: IAWSClient);
    class function New(Client: IAWSClient): ISESObjects;
    function SendEmail(Message: TSESMessage): IAWSResponse;
  end;

var
  sAWS_SES_URL: String;

implementation

{ TSESObjects }

constructor TSESObjects.Create(Client: IAWSClient);
begin
  inherited Create;
  FClient := Client;
end;

class function TSESObjects.New(Client: IAWSClient): ISESObjects;
begin
  Result := Create(Client);
end;

function TSESObjects.SendEmail(Message: TSESMessage): IAWSResponse;
const
  sAnd = '&';
var
  sConteudo: String;
  oStream: TStringStream;
  oAwsStream: TAWSStream;
begin

  sConteudo:='Action=SendEmail';
  sConteudo:=sConteudo+sAnd+'Destination.ToAddresses.member.1='+EncodeURLElement(Message.TOAddress);
  sConteudo:=sConteudo+sAnd+'Source='                          +EncodeURLElement(Message.From);
  sConteudo:=sConteudo+sAnd+'Message.Subject.Data='            +EncodeURLElement(Message.Subject);
  if Message.Format = teHtml then
   begin
      sConteudo:=sConteudo+sAnd+'Message.Body.Html.Data='      +EncodeURLElement(Message.Message);
      if Message.Charset <> EmptyStr then
        sConteudo:=sConteudo+sAnd+'Message.Body.Html.Charset='      +EncodeURLElement(Message.Charset);
    end
  else
    begin
      sConteudo:=sConteudo+sAnd+'Message.Body.Text.Data='      +EncodeURLElement(Message.Message);
      if Message.Charset <> EmptyStr then
        sConteudo:=sConteudo+sAnd+'Message.Body.Text.Charset='      +EncodeURLElement(Message.Charset);
    end;

  oStream := TStringStream.Create(sConteudo);
  oAwsStream := TAWSStream.Create(oStream);

  Result := FClient.Send(
    TAWSRequest.New(
      'POST', '', sAWS_SES_URL, '', '/', 'application/x-www-form-urlencoded', 'AWS3', '', '/', oAwsStream)
  );

  oStream.Free;
  oAwsStream.Free;

end;

{ TSESRegion }

constructor TSESRegion.Create(Client: IAWSClient; sRegion: String);
begin
  inherited Create;
  FClient := Client;
  sAWS_SES_URL:='email.'+sRegion+'.amazonaws.com';
end;

class function TSESRegion.New(Client: IAWSClient; sRegion: String): ISESRegion;
begin
  Result := Create(Client, sRegion);
end;

function TSESRegion.SESObjects: ISESObjects;
begin
  Result := TSESObjects.Create(FClient);
end;

end.

