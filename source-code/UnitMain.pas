unit UnitMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Graphics, FMX.Dialogs, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, IdBaseComponent, IdCookieManager,
  FMX.Edit, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.StdCtrls, DateUtils, FMX.Objects, REST.Client,
  REST.Types, System.JSON, IPPeerClient, Data.Bind.Components, Data.Bind.ObjectScope, FMX.TabControl, FMX.ListBox,
  FMX.WebBrowser, FMX.DialogService, FMX.ComboEdit, StrUtils;

type
  TFormMain = class(TForm)
    ButtonStart: TButton;
    EditUsername: TEdit;
    EditPassword: TEdit;
    IdCookieManagerGitlab: TIdCookieManager;
    IdHTTPGitlab: TIdHTTP;
    RESTClientGitlab: TRESTClient;
    RESTRequestGitlab: TRESTRequest;
    RESTResponseGitlab: TRESTResponse;
    TabControlMain: TTabControl;
    TableItemImages: TTabItem;
    TableItemLogs: TTabItem;
    MemoLog: TMemo;
    MemoImageList: TMemo;
    TabItemHelp: TTabItem;
    LabelUser: TLabel;
    LabelPassword: TLabel;
    ImageWise2C: TImage;
    EditK8S: TEdit;
    EditDNS: TEdit;
    EditEtcd: TEdit;
    EditDashboard: TEdit;
    EditFlannel: TEdit;
    EditPause: TEdit;
    LabelK8S: TLabel;
    LabelDNS: TLabel;
    LabelEtcd: TLabel;
    LabelDashboard: TLabel;
    LabelFlannel: TLabel;
    LabelPause: TLabel;
    ComboBoxOSType: TComboBox;
    WebBrowserGIF: TWebBrowser;
    MemoHelp: TMemo;
    LabelWaitting: TLabel;
    EditOS: TEdit;
    LabelOS: TLabel;
    ImageK8S: TImage;
    LabelKubernetesCNI: TLabel;
    EditKubernetesCNI: TEdit;
    TimerCheck: TTimer;
    TabItemHistory: TTabItem;
    MemoHistory: TMemo;
    WebBrowserHistory: TWebBrowser;
    WebBrowserHelp: TWebBrowser;
    TabItemContactUs: TTabItem;
    ButtonVersionSync: TButton;
    ComboBoxKubernetesVersion: TComboBox;
    procedure ButtonStartClick(Sender: TObject);
    procedure EditK8SKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure EditPauseKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure EditDNSKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure EditDashboardKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure EditFlannelKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure EditEtcdKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure TableItemImagesClick(Sender: TObject);
    procedure TabItemHelpClick(Sender: TObject);
    procedure TableItemLogsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EditPasswordKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure EditUsernameKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure ComboBoxOSTypeChange(Sender: TObject);
    procedure TimerCheckTimer(Sender: TObject);
    procedure ImageWise2CClick(Sender: TObject);
    procedure TabItemHistoryClick(Sender: TObject);
    procedure TabItemContactUsClick(Sender: TObject);
    procedure ButtonVersionSyncClick(Sender: TObject);
    procedure ComboBoxKubernetesVersionChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;
  api_token_key, datestring, project_id, job_id: string;
  LJSON: TJSONValue;
  Started, ProjectCreated, FoundJobID: Boolean;

implementation

{$R *.fmx}
{$R *.Macintosh.fmx MACOS}
{$R *.Windows.fmx MSWINDOWS}

type
  TAdapterJSONValue = class(TInterfacedObject, IRESTResponseJSON)
  private
    FJSONValue: TJSONValue;
  protected
    { IRESTResponseJSON }
    procedure AddJSONChangedEvent(const ANotify: TNotifyEvent);
    procedure RemoveJSONChangedEvent(const ANotify: TNotifyEvent);
    procedure GetJSONResponse(out AJSONValue: TJSONValue; out AHasOwner: Boolean);
    function HasJSONResponse: Boolean;
    function HasResponseContent: Boolean;
  public
    constructor Create(const AJSONValue: TJSONValue);
    destructor Destroy; override;
  end;
  { TAdapterJSONValue }

procedure TAdapterJSONValue.AddJSONChangedEvent(const ANotify: TNotifyEvent);
begin
  // Not implemented because we pass JSON in constructor and do not change it
end;

constructor TAdapterJSONValue.Create(const AJSONValue: TJSONValue);
begin
  FJSONValue := AJSONValue;
end;

destructor TAdapterJSONValue.Destroy;
begin
  // We own the JSONValue, so free it.
  FJSONValue.Free;
  inherited;
end;

procedure TAdapterJSONValue.GetJSONResponse(out AJSONValue: TJSONValue; out AHasOwner: Boolean);
begin
  AJSONValue := FJSONValue;
  AHasOwner := True; // We own this object
end;

function TAdapterJSONValue.HasJSONResponse: Boolean;
begin
  result := FJSONValue <> nil;
end;

function TAdapterJSONValue.HasResponseContent: Boolean;
begin
  result := FJSONValue <> nil;
end;

procedure TAdapterJSONValue.RemoveJSONChangedEvent(const ANotify: TNotifyEvent);
begin
  // Not implemented because we pass JSON in constructor and do not change it
end;

procedure ShowMessageOnMultiDevice(MessageStr: string);
begin
  TDialogService.MessageDialog(MessageStr, System.UITypes.TMsgDlgType.mtInformation, [System.UITypes.TMsgDlgBtn.mbOK], System.UITypes.TMsgDlgBtn.mbYes, 0,
    // Use an anonymous method to make sure the acknowledgment appears as expected.
    procedure(const AResult: TModalResult)
    begin
    end)
end;

procedure CreateGitProject;
var
  gitlab_ci_str_list: TStringList;
  Response, gitlab_ci_str: String;
  str_position, i: integer;
begin
  // 创建Gitlab项目
  ProjectCreated := False;
  FormMain.RESTClientGitlab.BaseURL := 'https://gitlab.com/api/v3/projects?private_token=' + api_token_key;
  FormMain.RESTRequestGitlab.Method := rmPOST;
  FormMain.RESTRequestGitlab.Params.Clear;
  FormMain.RESTRequestGitlab.AddParameter('body', '{"name": "wise2c-get-k8s-' + datestring + '"}', pkREQUESTBODY);
  FormMain.RESTRequestGitlab.Params[0].ContentType := ctAPPLICATION_JSON;
  try
    Application.ProcessMessages;
    FormMain.RESTRequestGitlab.Execute;
    LJSON := TJSONObject.ParseJSONValue(FormMain.RESTResponseGitlab.Content);
    if LJSON = nil then
      raise Exception.Create('无效的JSON返回! 请检查提交的内容是否正确并确保网络连接正常');
    FormMain.MemoLog.Lines.Add('Project Information:');
    FormMain.MemoLog.Lines.Add('');
    FormMain.MemoLog.Lines.Add(FormMain.RESTResponseGitlab.Content);
    FormMain.MemoLog.Lines.Add('');
    FormMain.MemoLog.Lines.Add('Files Information:');
    FormMain.MemoLog.Lines.Add('');
    if Length(FormMain.RESTResponseGitlab.Content) > 0 then
    begin
      project_id := '';
      str_position := pos('{"id":', FormMain.RESTResponseGitlab.Content);
      for i := str_position + 6 to Length(FormMain.RESTResponseGitlab.Content) do
        if FormMain.RESTResponseGitlab.Content[i] = ',' then
          break
        else
          project_id := project_id + FormMain.RESTResponseGitlab.Content[i];
      if project_id <> '' then
      begin
        FormMain.LabelWaitting.Text := '创建镜像制作任务...';

        // 创建Dockerfile文件内容
        gitlab_ci_str_list := TStringList.Create;
        gitlab_ci_str := 'content=';
        gitlab_ci_str := gitlab_ci_str + FormMain.LabelOS.Text + FormMain.EditOS.Text + chr(10);

        if FormMain.ComboBoxOSType.ItemIndex = 0 then
        begin
          gitlab_ci_str := gitlab_ci_str + 'RUN apt-get update && apt-get install -y apt-transport-https curl && \' + chr(10);
          gitlab_ci_str := gitlab_ci_str + '    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'ADD kubernetes.list /etc/apt/sources.list.d/' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'RUN apt-get update && apt-get install -d -y kubelet=' + FormMain.EditK8S.Text + '-00 kubeadm=' + FormMain.EditK8S.Text + '-00 kubectl=' + FormMain.EditK8S.Text +
            '-00 kubernetes-cni=' + FormMain.EditKubernetesCNI.Text + '-00' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'RUN mkdir /debs && cp $(find /var/cache/apt/archives -name *.deb) /debs/ && tar zcvf /kubernetes-debs.tar.gz -C / debs' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'COPY ./kubernetes-images.tar.bz2 /' + chr(10);
        end
        else
        begin
          gitlab_ci_str := gitlab_ci_str + 'RUN sed -i "s/keepcache=0/keepcache=1/" /etc/yum.conf' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'ADD kubernetes.repo /etc/yum.repos.d/' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'RUN yum install -y kubelet-' + FormMain.EditK8S.Text + '-0 kubeadm-' + FormMain.EditK8S.Text + '-0 kubectl-' + FormMain.EditK8S.Text + '-0 kubernetes-cni-' +
            FormMain.EditKubernetesCNI.Text + '-0' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'RUN mkdir /rpms && cp $(find /var/cache/yum/x86_64 -name *.rpm) /rpms/ && tar zcvf /kubernetes-rpms.tar.gz -C / rpms' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'COPY ./kubernetes-images.tar.bz2 /' + chr(10);
        end;
        gitlab_ci_str_list.Clear;
        gitlab_ci_str_list.Add(gitlab_ci_str);
        FormMain.IdHTTPGitlab.Request.CustomHeaders.Clear;
        FormMain.IdHTTPGitlab.Request.CustomHeaders.Add('PRIVATE-TOKEN: ' + api_token_key);
        Application.ProcessMessages;
        Response := FormMain.IdHTTPGitlab.Post('https://gitlab.com/api/v4/projects/' + project_id + '/repository/files/Dockerfile?branch=master&commit_message=Create%20Dockerfile', gitlab_ci_str_list);
        FormMain.MemoLog.Lines.Add(Response);
        FormMain.MemoLog.Lines.Add('');

        // 创建kubernetes.list文件内容或kubernetes.repo文件内容
        gitlab_ci_str := 'content=';
        if FormMain.ComboBoxOSType.ItemIndex = 0 then
        begin
          gitlab_ci_str := gitlab_ci_str + 'deb http://apt.kubernetes.io/ kubernetes-xenial main';
          gitlab_ci_str_list.Clear;
          gitlab_ci_str_list.Add(gitlab_ci_str);
          Application.ProcessMessages;
          Response := FormMain.IdHTTPGitlab.Post('https://gitlab.com/api/v4/projects/' + project_id + '/repository/files/kubernetes.list?branch=master&commit_message=Create%20kubernetes.list', gitlab_ci_str_list);
          FormMain.MemoLog.Lines.Add(Response);
          FormMain.MemoLog.Lines.Add('');
        end
        else
        begin
          gitlab_ci_str := gitlab_ci_str + '[kubernetes]' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'name=Kubernetes' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'enabled=1' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'gpgcheck=1' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'repo_gpgcheck=1' + chr(10);
          gitlab_ci_str := gitlab_ci_str + 'gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' + chr(10);
          gitlab_ci_str_list.Clear;
          gitlab_ci_str_list.Add(gitlab_ci_str);
          Application.ProcessMessages;
          Response := FormMain.IdHTTPGitlab.Post('https://gitlab.com/api/v4/projects/' + project_id + '/repository/files/kubernetes.repo?branch=master&commit_message=Create%20kubernetes.repo', gitlab_ci_str_list);
          FormMain.MemoLog.Lines.Add(Response);
          FormMain.MemoLog.Lines.Add('');
        end;

        // 创建gitlab-ci流水线文件内容
        gitlab_ci_str_list := TStringList.Create;
        gitlab_ci_str := 'content=';
        gitlab_ci_str := gitlab_ci_str + 'build_image:' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '    image: docker:git' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '    services:' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '        - docker:dind' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '    script:' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '        - docker login -u gitlab-ci-token -p $CI_BUILD_TOKEN registry.gitlab.com' + chr(10);

        // 加入多行docker pull命令获取镜像列表
        if FormMain.MemoImageList.Lines.Count <> 0 then
          for i := 1 to FormMain.MemoImageList.Lines.Count do
            gitlab_ci_str := gitlab_ci_str + '        - docker pull ' + FormMain.MemoImageList.Lines[i - 1] + chr(10);
        gitlab_ci_str := gitlab_ci_str + '        - docker save $(docker images |grep -v TAG |awk ''{print $1":"$2}'') | bzip2 -z -9 > ./kubernetes-images.tar.bz2' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '        - docker build -t tempimage .' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '        - docker run --name=alanpeng -itd --entrypoint=/bin/bash tempimage' + chr(10);
        if FormMain.ComboBoxOSType.ItemIndex = 0 then
          gitlab_ci_str := gitlab_ci_str + '        - docker cp alanpeng:/kubernetes-debs.tar.gz ./' + chr(10)
        else
          gitlab_ci_str := gitlab_ci_str + '        - docker cp alanpeng:/kubernetes-rpms.tar.gz ./' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '        - docker stop alanpeng' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '        - docker rm alanpeng' + chr(10);
        if FormMain.ComboBoxOSType.ItemIndex = 0 then
          gitlab_ci_str := gitlab_ci_str + '        - tar zcvf ./kubernetes-packages.tar.gz ./kubernetes-images.tar.bz2 ./kubernetes-debs.tar.gz' + chr(10)
        else
          gitlab_ci_str := gitlab_ci_str + '        - tar zcvf ./kubernetes-packages.tar.gz ./kubernetes-images.tar.bz2 ./kubernetes-rpms.tar.gz' + chr(10);

        gitlab_ci_str := gitlab_ci_str + '        - rm -f ./kubernetes-images.tar.bz2' + chr(10);
        if FormMain.ComboBoxOSType.ItemIndex = 0 then
          gitlab_ci_str := gitlab_ci_str + '        - rm -f ./kubernetes-debs.tar.gz' + chr(10)
        else
          gitlab_ci_str := gitlab_ci_str + '        - rm -f ./kubernetes-rpms.tar.gz' + chr(10);

        gitlab_ci_str := gitlab_ci_str + '        - echo "FROM tempimage" > ./Dockerfile' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '        - echo "COPY kubernetes-packages.tar.gz /" >> ./Dockerfile' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '        - docker build -t registry.gitlab.com/' + FormMain.EditUsername.Text + '/wise2c-get-k8s-' + datestring + ' .' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '        - docker push registry.gitlab.com/' + FormMain.EditUsername.Text + '/wise2c-get-k8s-' + datestring + chr(10);

        gitlab_ci_str := gitlab_ci_str + '        - apk add --no-cache curl' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '        - curl -s --upload-file ./kubernetes-packages.tar.gz https://transfer.sh/kubernetes-packages.tar.gz' + chr(10);
        gitlab_ci_str := gitlab_ci_str + '    when: always' + chr(10);
        gitlab_ci_str_list.Clear;
        gitlab_ci_str_list.Add(gitlab_ci_str);

        // 在Git项目里创建新文件.gitlab-ci.yaml
        Application.ProcessMessages;
        Response := FormMain.IdHTTPGitlab.Post('https://gitlab.com/api/v4/projects/' + project_id + '/repository/files/.gitlab-ci.yml?branch=master&commit_message=Create%20.gitlab-ci.yml', gitlab_ci_str_list);
        FormMain.MemoLog.Lines.Add(Response);
        FormMain.MemoLog.Lines.Add('');
        gitlab_ci_str_list.Free;
      end;
      FormMain.LabelWaitting.Text := '成功创建镜像制作任务！';
      ProjectCreated := True;
    end;
  except
    on E: Exception do
    begin
      ProjectCreated := False;
      FormMain.LabelWaitting.Text := '创建任务异常，请重试！';
      ShowMessageOnMultiDevice('创建流水线任务遇到错误，请检查具体原因：' + E.Message);
    end;
  end;
end;

procedure GetJobID;
var
  Response: String;
  i, str_position: integer;
begin
  job_id := '';
  FoundJobID := False;
  try
    Application.ProcessMessages;
    Response := FormMain.IdHTTPGitlab.Get('https://gitlab.com/api/v4/projects/' + project_id + '/jobs');
    if Length(Response) > 0 then
    begin
      str_position := pos('[{"id":', Response);
      if str_position > 0 then
      begin
        for i := str_position + 7 to Length(Response) do
          if Response[i] = ',' then
            break
          else
            job_id := job_id + Response[i];
        if job_id <> '' then
        begin
          FormMain.MemoLog.Lines.Add('找到流水线ID：' + job_id);
          FormMain.MemoLog.Lines.Add('');
          FoundJobID := True;
        end
        else
        begin
          FormMain.MemoLog.Lines.Add('异常：未找到流水线ID！');
          FormMain.MemoLog.Lines.Add('');
          FormMain.LabelWaitting.Text := '程序异常：请重新创建构建任务。'
        end;
      end
      else
      begin
        FormMain.MemoLog.Lines.Add('异常：未找到流水线ID！');
        FormMain.MemoLog.Lines.Add('');
        FormMain.LabelWaitting.Text := '程序异常：请重新创建构建任务。'
      end;
    end
    else
    begin
      FormMain.MemoLog.Lines.Add('No http response with "Sign in" page.');
      FormMain.MemoLog.Lines.Add('');
    end;
  except
    on E: Exception do
    begin
      ShowMessageOnMultiDevice('查询流水线号遇到错误，请检查具体原因：' + E.Message);
      FormMain.LabelWaitting.Text := '查询流水线号遇到错误';
    end;
  end;
end;

procedure CheckJobStatus;
var
  Response, jobstatus, downloadstr: String;
  i, str_position: integer;
  historystrlist: TStringList;
begin
  jobstatus := '';
  try
    Application.ProcessMessages;
    Response := FormMain.IdHTTPGitlab.Get('https://gitlab.com/api/v4/projects/' + project_id + '/jobs/' + job_id);
    if Length(Response) > 0 then
    begin
      str_position := pos(',"status":"', Response);
      if str_position > 0 then
      begin
        for i := str_position + 11 to Length(Response) do
          if Response[i] = '"' then
            break
          else
            jobstatus := jobstatus + Response[i];
        if jobstatus = 'failed' then
        begin
          FormMain.TimerCheck.Enabled := False;
          FormMain.LabelWaitting.Text := '任务执行失败，请查阅详细日志！';
          try
            Response := FormMain.IdHTTPGitlab.Get('https://gitlab.com/api/v4/projects/' + project_id + '/jobs/' + job_id + '/trace');
            if Length(Response) > 0 then
            begin
              FormMain.MemoLog.Lines.Clear;
              FormMain.MemoLog.Lines.Add(Response);
            end
            else
              FormMain.MemoLog.Lines.Add('获取运行日志失败！');
          except
            on E: Exception do
            begin
              ShowMessageOnMultiDevice('获取流水线日志遇到错误，请检查具体原因：' + E.Message);
              FormMain.LabelWaitting.Text := '获取流水线日志遇到错误';
            end;
          end;
        end
        else if jobstatus = 'success' then
        begin
          FormMain.TimerCheck.Enabled := False;
          FormMain.LabelWaitting.Text := '';
          FormMain.TabControlMain.GotoVisibleTab(2);
          try
            Response := FormMain.IdHTTPGitlab.Get('https://gitlab.com/api/v4/projects/' + project_id + '/jobs/' + job_id + '/trace');
            if Length(Response) > 0 then
            begin
              FormMain.MemoLog.Lines.Clear;
              FormMain.MemoLog.Lines.Add(Response);
              downloadstr := '';
              str_position := pos('[0;m' + chr(10) + 'https://transfer.sh/', Response);
              if str_position > 0 then
              begin
                for i := str_position + 25 to Length(Response) do
                  if Response[i] = '/' then
                    break
                  else
                    downloadstr := downloadstr + Response[i];
                if downloadstr <> '' then
                begin
                  FormMain.MemoHistory.Lines.Insert(0, '');
                  FormMain.MemoHistory.Lines.Insert(0, 'Time:  ' + datestring + chr(9) + 'Image:' + chr(9) + 'registry.gitlab.com/' + FormMain.EditUsername.Text + '/wise2c-get-k8s-' + datestring);
                  FormMain.MemoHistory.Lines.Insert(0, 'Time:  ' + datestring + chr(9) + 'URL:' + chr(9) + 'https://transfer.sh/' + downloadstr + '/kubernetes-packages.tar.gz');
                  historystrlist := TStringList.Create;
                  for i := 0 to FormMain.MemoHistory.Lines.Count - 1 do
                    historystrlist.Add(FormMain.MemoHistory.Lines[i]);
                  historystrlist.SaveToFile(GetHomePath + '/History.txt', TEncoding.ANSI);
                  historystrlist.Free;
                  FormMain.MemoHistory.Lines.Insert(0, '');
                  FormMain.MemoHistory.Lines.Insert(0, '以下是历史记录，下载链接有效期14天，镜像长期有效：');
                  FormMain.MemoHistory.Lines.Insert(0, '');
                  FormMain.MemoHistory.Lines.Insert(0, '');
                  FormMain.MemoHistory.Lines.Insert(0, '   分别使用rpm -ivh *.rpm或dpkg -i *.deb进行安装');
                  FormMain.MemoHistory.Lines.Insert(0, '   解压开tar.gz后缀的文件即可得到CentOS的RPM包或Ubuntu下的deb包');
                  FormMain.MemoHistory.Lines.Insert(0, '   使用命令 docker load -i kubernetes-images.tar.bz2 即可导入全部镜像');
                  FormMain.MemoHistory.Lines.Insert(0, '   kubernetes-debs.tar.gz 或 kubernetes-rpms.tar.gz');
                  FormMain.MemoHistory.Lines.Insert(0, '   得到两个文件，分别是镜像文件kubernetes-images.tar.bz2以及OS依赖包文件：');
                  FormMain.MemoHistory.Lines.Insert(0, '');
                  FormMain.MemoHistory.Lines.Insert(0, '   tar zxvf kubernetes-packages.tar.gz');
                  FormMain.MemoHistory.Lines.Insert(0, '   docker cp wise2c-get-k8s:/kubernetes-packages.tar.gz ./');
                  FormMain.MemoHistory.Lines.Insert(0, '     registry.gitlab.com/' + FormMain.EditUsername.Text + '/wise2c-get-k8s-' + datestring);
                  FormMain.MemoHistory.Lines.Insert(0, '   docker run -itd --name=wise2c-get-k8s --entrypoint=/bin/bash \');
                  FormMain.MemoHistory.Lines.Insert(0, '   docker pull registry.gitlab.com/' + FormMain.EditUsername.Text + '/wise2c-get-k8s-' + datestring);
                  FormMain.MemoHistory.Lines.Insert(0, '   注意这里的********为你Gitlab站点用户登录密码');
                  FormMain.MemoHistory.Lines.Insert(0, '   docker login registry.gitlab.com -u="' + FormMain.EditUsername.Text + '" -p="********"');
                  FormMain.MemoHistory.Lines.Insert(0, '2. 在Docker环境输入以下命令：');
                  FormMain.MemoHistory.Lines.Insert(0, '');
                  FormMain.MemoHistory.Lines.Insert(0, '   https://transfer.sh/' + downloadstr + '/kubernetes-packages.tar.gz');
                  FormMain.MemoHistory.Lines.Insert(0, '1. 直接使用浏览器或迅雷之类的工具下载文件：');
                  FormMain.MemoHistory.Lines.Insert(0, '您可以选择两种方式获得软件包：');
                  FormMain.WebBrowserHistory.URL := 'file://' + GetHomePath + '/cicd.png';
                end
                else
                begin
                  FormMain.MemoLog.Lines.Add('任务完成，但获取下载链接失败！请重新运行程序。');
                  FormMain.LabelWaitting.Text := '获取下载链接失败！';
                end;
              end
              else
              begin
                FormMain.MemoLog.Lines.Add('任务完成，但获取下载链接失败！，请重新运行程序');
                FormMain.LabelWaitting.Text := '获取下载链接失败！';
              end;
            end
            else
            begin
              FormMain.MemoLog.Lines.Add('任务完成，但获取运行日志失败！');
              FormMain.LabelWaitting.Text := '获取运行日志失败！';
            end;
          except
            on E: Exception do
            begin
              ShowMessageOnMultiDevice('获取流水线日志遇到错误，请检查具体原因：' + E.Message);
              FormMain.LabelWaitting.Text := '获取流水线日志遇到错误';
            end;
          end;
        end
        else
        begin
          FormMain.TimerCheck.Enabled := True;
          FormMain.LabelWaitting.Text := '镜像制作中，请耐心等候...';
          FormMain.MemoLog.Text := FormMain.MemoLog.Text + ('>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
        end;
      end
      else
      begin
        FormMain.TimerCheck.Enabled := True;
        FormMain.LabelWaitting.Text := '检查任务状态失败...';
        FormMain.MemoLog.Lines.Add(Response);
        FormMain.MemoLog.Lines.Add('');
      end;
    end
    else
    begin
      FormMain.MemoLog.Lines.Add('No http response with job status.');
      FormMain.MemoLog.Lines.Add('');
    end;
  except
    on E: Exception do
    begin
      ShowMessageOnMultiDevice('获取流水线任务列表遇到错误，请检查具体原因：' + E.Message);
      FormMain.LabelWaitting.Text := '获取流水线列表失败';
    end;
  end;
end;

procedure TFormMain.ButtonStartClick(Sender: TObject);
Var
  token, Response, api_token_id, monthstr, daystr, hourstr, minutestr, secondstr: String;
  // cookie: String;
  i, str_position: integer;
  postbody, configstrlist: TStringList;
begin
  Started := True;
  LabelWaitting.Visible := True;
  LabelWaitting.Text := '正在登陆Gitlab，请稍候...';
  TabControlMain.GotoVisibleTab(1);
  WebBrowserGIF.URL := 'file://' + GetHomePath + '/waitting.gif';
  Application.ProcessMessages;
  WebBrowserGIF.Navigate;
  MemoLog.Lines.Clear;
  MemoLog.Lines.Add('Connecting to Gitlab...');
  MemoLog.Lines.Add('');
  ButtonStart.Enabled := False;
  // 整个调用过程由IdHTTP自动处理cookie，需要对IdHTTP控件的属性进行对象绑定，
  // 即IdHTTPGitlabd的CookieManager为IdCookieManagerGitlab;

  // 访问Sign in页面获取其authenticity_token
  token := '';
  Response := '';
  // cookie := '';
  IdHTTPGitlab.HandleRedirects := True;
  try
    Application.ProcessMessages;
    Response := IdHTTPGitlab.Get('https://gitlab.com/users/sign_in');
    {
      for i := 0 to IdHTTPGitlab.CookieManager.CookieCollection.Count - 1 do
      cookie := cookie + IdHTTPGitlab.CookieManager.CookieCollection.Cookies[i].Value;
    }
    if (Length(Response) > 0) then
    begin
      str_position := pos('name="authenticity_token" value=', Response);
      if str_position > 0 then
      begin
        for i := str_position + 33 to Length(Response) do
          if Response[i] = '"' then
            break
          else
            token := token + Response[i];
        if token <> '' then
        begin
          MemoLog.Lines.Add('authenticity_token in "Sign in" page:');
          MemoLog.Lines.Add('');
          MemoLog.Lines.Add(token);
          MemoLog.Lines.Add('');

          // 使用用户名密码登录Gitlab
          postbody := TStringList.Create;
          postbody.Add('user[login]=' + EditUsername.Text);
          postbody.Add('user[password]=' + EditPassword.Text);
          postbody.Add('authenticity_token=' + token);
          IdHTTPGitlab.Request.AcceptCharSet := 'UTF-8';
          IdHTTPGitlab.Request.ContentType := 'application/x-www-form-urlencoded';
          IdHTTPGitlab.Request.Host := 'gitlab.com';
          IdHTTPGitlab.Request.Connection := 'Keep-Alive';
          IdHTTPGitlab.Request.Referer := 'https://gitlab.com/users/sign_in';
          IdHTTPGitlab.HTTPOptions := [hoForceEncodeParams, hoTreat302Like303];
          try
            Response := '';
            Application.ProcessMessages;
            Response := IdHTTPGitlab.Post('https://gitlab.com/users/sign_in', postbody);
            if (Length(Response) > 0) then
            begin
              if pos('Invalid Login or password.', Response) > 0 then
              begin
                LabelWaitting.Text := '登录用户名或密码错误！';
                MemoLog.Lines.Add('Invalid Login or password.');
                MemoLog.Lines.Add('');
              end
              else if pos('<title>Projects · Dashboard · GitLab</title>', Response) > 0 then
              begin
                LabelWaitting.Text := '        登录成功！';
                configstrlist := TStringList.Create;
                configstrlist.Clear;
                configstrlist.Add(EditUsername.Text);
                configstrlist.SaveToFile(GetHomePath + '/Settings.conf', TEncoding.ANSI);
                configstrlist.Free;
                MemoLog.Lines.Add('You are signed in!');
                MemoLog.Lines.Add('');
                // 访问Personal Access Token页面获取其authenticity_token
                try
                  token := '';
                  Application.ProcessMessages;
                  Response := IdHTTPGitlab.Get('https://gitlab.com/profile/personal_access_tokens');
                  if (Length(Response) > 0) then
                  begin
                    str_position := pos('name="authenticity_token" value=', Response);
                    for i := str_position + 33 to Length(Response) do
                      if Response[i] = '"' then
                        break
                      else
                        token := token + Response[i];
                    if token <> '' then
                    begin
                      MemoLog.Lines.Add('authenticity_token in "Personal Access Tokens" page:');
                      MemoLog.Lines.Add('');
                      MemoLog.Lines.Add(token);
                      MemoLog.Lines.Add('');
                      // 创建个人API令牌

                      monthstr := IntToStr(MonthOf(now));
                      if Length(monthstr) = 1 then
                        monthstr := '0' + monthstr;
                      daystr := IntToStr(DayOf(now));
                      if Length(daystr) = 1 then
                        daystr := '0' + daystr;
                      hourstr := IntToStr(HourOf(now));
                      if Length(hourstr) = 1 then
                        hourstr := '0' + hourstr;
                      minutestr := IntToStr(MinuteOf(now));
                      if Length(minutestr) = 1 then
                        minutestr := '0' + minutestr;
                      secondstr := IntToStr(SecondOf(now));
                      if Length(secondstr) = 1 then
                        secondstr := '0' + secondstr;

                      datestring := IntToStr(YearOf(now)) + monthstr + daystr + hourstr + minutestr + secondstr;
                      postbody.Clear;
                      postbody.Add('personal_access_token[name]=' + 'wise2c-get-k8s-' + datestring);
                      postbody.Add('personal_access_token[expires_at]=');
                      postbody.Add('personal_access_token[scopes][]=api');
                      postbody.Add('personal_access_token[scopes][]=read_user');
                      postbody.Add('personal_access_token[scopes][]=read_repository');
                      postbody.Add('personal_access_token[scopes][]=read_registry');
                      postbody.Add('authenticity_token=' + token);
                      try
                        Response := '';
                        Application.ProcessMessages;
                        Response := IdHTTPGitlab.Post('https://gitlab.com/profile/personal_access_tokens', postbody);
                        // 保存API令牌ID及Key值
                        if (Length(Response) > 0) then
                        begin
                          if pos('created-personal-access-token', Response) > 0 then
                          begin
                            api_token_id := '';
                            for i := pos('/profile/personal_access_tokens/', Response) + 32 to Length(Response) do
                              if Response[i] = '/' then
                                break
                              else
                                api_token_id := api_token_id + Response[i];

                            // 判断是否存在API Token ID
                            if api_token_id <> '' then
                            begin
                              MemoLog.Lines.Add('Personal Access Token ID:');
                              MemoLog.Lines.Add('');
                              MemoLog.Lines.Add(api_token_id);
                              MemoLog.Lines.Add('');
                            end
                            else
                            begin
                              MemoLog.Lines.Add('Could not find personal access token id, please see http response as below:');
                              MemoLog.Lines.Add('');
                              MemoLog.Lines.Add(Response);
                              MemoLog.Lines.Add('');
                              MemoLog.Lines.Add('############################################################################');
                              MemoLog.Lines.Add('');
                            end;

                            api_token_key := '';
                            for i := pos('id="created-personal-access-token" value=', Response) + 42 to Length(Response) do
                              if Response[i] = '"' then
                                break
                              else
                                api_token_key := api_token_key + Response[i];

                            // 判断是否存在API Token Key
                            if api_token_key <> '' then
                            begin
                              MemoLog.Lines.Add('Personal Access Token Key:');
                              MemoLog.Lines.Add('');
                              MemoLog.Lines.Add(api_token_key);
                              MemoLog.Lines.Add('');
                            end
                            else
                            begin
                              MemoLog.Lines.Add('Could not find personal access token key, please see http response as below:');
                              MemoLog.Lines.Add('');
                              MemoLog.Lines.Add(Response);
                              MemoLog.Lines.Add('');
                            end;

                            // 创建Gitlab项目
                            CreateGitProject;

                            // 获取流水线JobID
                            if ProjectCreated then
                            begin
                              GetJobID;
                              MemoLog.Lines.Add('JobID: ' + job_id);
                              MemoLog.Lines.Add('');
                            end;
                            // 轮询任务执行结果
                            if FoundJobID then
                            begin
                              MemoLog.Lines.Clear;
                              MemoLog.Lines.Add('This might take several minutes.');
                              MemoLog.Lines.Add('');
                              CheckJobStatus;
                            end;

                            // 释放postbody资源及Cookie缓存
                            postbody.Free;
                            IdHTTPGitlab.CookieManager.CookieCollection.Clear;
                          end
                          else
                          begin
                            MemoLog.Lines.Add('Could not create personal access token, please see http response as below:');
                            MemoLog.Lines.Add('');
                            MemoLog.Lines.Add(Response);
                            MemoLog.Lines.Add('');
                          end;
                        end
                        else
                        begin
                          MemoLog.Lines.Add('No http response with "Personal Access Tokens" page while posting request.');
                          MemoLog.Lines.Add('');
                        end;
                      except
                        on E: Exception do
                          ShowMessageOnMultiDevice('创建API令牌遇到错误，请检查具体原因：' + E.Message);
                      end;
                    end
                    else
                    begin
                      MemoLog.Lines.Add('No authenticity_token found in "Personal Access Tokens" page, please see http response as below:');
                      MemoLog.Lines.Add('');
                      MemoLog.Lines.Add(Response);
                      MemoLog.Lines.Add('');
                    end;
                  end
                  else
                  begin
                    MemoLog.Lines.Add('No http response with "Personal Access Tokens" page.');
                    MemoLog.Lines.Add('');
                  end;
                except
                  on E: Exception do
                    ShowMessageOnMultiDevice('访问Access Tokens页面遇到错误，请检查具体原因：' + E.Message);
                end;
              end
              else
              begin
                LabelWaitting.Text := '登录失败，请核对登录信息！';
                MemoLog.Lines.Add('You ar not signed in, please see http response as below:');
                MemoLog.Lines.Add('');
                MemoLog.Lines.Add(Response);
                MemoLog.Lines.Add('');
              end;
            end
            else
            begin
              MemoLog.Lines.Add('No http response with "Sign in" page while posting request.');
              MemoLog.Lines.Add('');
            end;
          except
            on E: Exception do
              ShowMessageOnMultiDevice('登录Gitlab遇到错误，请检查具体原因：' + E.Message);
          end;
        end
        else
        begin
          MemoLog.Lines.Clear;
          MemoLog.Lines.Add('No authenticity_token found in "Sign in" page, please see http response as below:');
          MemoLog.Lines.Add('');
          MemoLog.Lines.Add(Response);
          MemoLog.Lines.Add('');
        end;
      end
    end
    else
    begin
      MemoLog.Lines.Clear;
      MemoLog.Lines.Add('No http response with "Sign in" page.');
      MemoLog.Lines.Add('');
    end;
  except
    on E: Exception do
      ShowMessageOnMultiDevice('访问Gitlab登录页面遇到错误，请检查具体原因：' + E.Message);
  end;
  ButtonStart.Enabled := True;
end;

procedure TFormMain.ButtonVersionSyncClick(Sender: TObject);
var
  Response: String;
  TempMemo: TMemo;
  i: integer;
begin
  ButtonVersionSync.Enabled := False;
  try
    Application.ProcessMessages;
    Response := IdHTTPGitlab.Get('https://gitlab.com/wise2c/kubernetes-version/raw/master/kubernetes-version-list.txt');
    if Response <> '' then
    begin
      TempMemo := TMemo.Create(FormMain);
      TempMemo.Text := Response;
      ComboBoxKubernetesVersion.Items.Clear;
      for i := 1 to TempMemo.Lines.Count do
        ComboBoxKubernetesVersion.Items.Add(TempMemo.Lines[i - 1]);
      ComboBoxKubernetesVersion.ItemIndex := 0;
      ComboBoxKubernetesVersion.Visible := True;
      TempMemo.Free;
    end
    else
      ShowMessageOnMultiDevice('Kubernetes版本信息返回为空，请检查具体原因');
  except
    on E: Exception do
      ShowMessageOnMultiDevice('获取Kubernetes版本信息遇到错误，请检查具体原因：' + E.Message);
  end;
  ButtonVersionSync.Enabled := True;
end;

procedure TFormMain.ComboBoxKubernetesVersionChange(Sender: TObject);
var
  Response, flannelversion: String;
begin
  ComboBoxKubernetesVersion.Enabled := False;
  try
    Application.ProcessMessages;
    Response := IdHTTPGitlab.Get('https://gitlab.com/wise2c/kubernetes-version/raw/master/versions/' + ComboBoxKubernetesVersion.Items[ComboBoxKubernetesVersion.ItemIndex] + '.txt');
    if Response <> '' then
    begin
      MemoImageList.Text := Response;
      EditEtcd.Text := RightStr(MemoImageList.Lines[0], (Length(MemoImageList.Lines[0]) - pos(':', MemoImageList.Lines[0])));
      EditPause.Text := RightStr(MemoImageList.Lines[1], (Length(MemoImageList.Lines[1]) - pos(':', MemoImageList.Lines[1])));
      EditK8S.Text := RightStr(ComboBoxKubernetesVersion.Items[ComboBoxKubernetesVersion.ItemIndex], Length(ComboBoxKubernetesVersion.Items[ComboBoxKubernetesVersion.ItemIndex]) - 1);
      EditDNS.Text := RightStr(MemoImageList.Lines[6], (Length(MemoImageList.Lines[3]) - pos(':', MemoImageList.Lines[3])));
      EditDashboard.Text := RightStr(MemoImageList.Lines[9], (Length(MemoImageList.Lines[4]) - pos(':', MemoImageList.Lines[4])));
      flannelversion := RightStr(MemoImageList.Lines[10], (Length(MemoImageList.Lines[10]) - pos(':', MemoImageList.Lines[10]) - 1));
      EditFlannel.Text := LeftStr(flannelversion, Length(flannelversion) - 6);
    end
    else
      ShowMessageOnMultiDevice('Kubernetes版本信息返回为空，请检查具体原因');
  except
    on E: Exception do
      ShowMessageOnMultiDevice('获取Kubernetes组件信息失败，请检查具体原因：' + E.Message);
  end;
  ComboBoxKubernetesVersion.Enabled := True;
end;

procedure TFormMain.ComboBoxOSTypeChange(Sender: TObject);
begin
  if ComboBoxOSType.ItemIndex = 0 then
  begin
    LabelOS.Text := 'FROM ubuntu:';
    EditOS.Text := '16.04';
  end
  else
  begin
    LabelOS.Text := 'FROM centos:';
    EditOS.Text := '7.4.1708';
  end;
end;

procedure TFormMain.EditDashboardKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  MemoImageList.Lines.Strings[9] := 'k8s.gcr.io/kubernetes-dashboard-amd64:v' + EditDashboard.Text;
  if EditDashboard.Text = '' then
    ButtonStart.Enabled := False
  else
    ButtonStart.Enabled := True;
end;

procedure TFormMain.EditDNSKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  MemoImageList.Lines.Strings[6] := 'k8s.gcr.io/k8s-dns-sidecar-amd64:' + EditDNS.Text;
  MemoImageList.Lines.Strings[7] := 'k8s.gcr.io/k8s-dns-kube-dns-amd64:' + EditDNS.Text;
  MemoImageList.Lines.Strings[8] := 'k8s.gcr.io/k8s-dns-dnsmasq-nanny-amd64:' + EditDNS.Text;
  if EditDNS.Text = '' then
    ButtonStart.Enabled := False
  else
    ButtonStart.Enabled := True;
end;

procedure TFormMain.EditEtcdKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  MemoImageList.Lines.Strings[0] := 'k8s.gcr.io/etcd-amd64:' + EditEtcd.Text;
  if EditEtcd.Text = '' then
    ButtonStart.Enabled := False
  else
    ButtonStart.Enabled := True;
end;

procedure TFormMain.EditFlannelKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  MemoImageList.Lines.Strings[10] := 'quay.io/coreos/flannel:v' + EditFlannel.Text + '-amd64';
  if EditFlannel.Text = '' then
    ButtonStart.Enabled := False
  else
    ButtonStart.Enabled := True;
end;

procedure TFormMain.EditK8SKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  MemoImageList.Lines.Strings[2] := 'k8s.gcr.io/kube-apiserver-amd64:v' + EditK8S.Text;
  MemoImageList.Lines.Strings[3] := 'k8s.gcr.io/kube-controller-manager-amd64:v' + EditK8S.Text;
  MemoImageList.Lines.Strings[4] := 'k8s.gcr.io/kube-scheduler:v' + EditK8S.Text;
  MemoImageList.Lines.Strings[5] := 'k8s.gcr.io/kube-proxy-amd64:v' + EditK8S.Text;
  if EditK8S.Text = '' then
    ButtonStart.Enabled := False
  else
    ButtonStart.Enabled := True;
end;

procedure TFormMain.EditPasswordKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if (EditUsername.Text <> '') and (EditPassword.Text <> '') then
    ButtonStart.Enabled := True
  else
    ButtonStart.Enabled := False;
end;

procedure TFormMain.EditPauseKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  MemoImageList.Lines.Strings[1] := 'k8s.gcr.io/pause-amd64:' + EditPause.Text;
  if EditPause.Text = '' then
    ButtonStart.Enabled := False
  else
    ButtonStart.Enabled := True;
end;

procedure TFormMain.EditUsernameKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if (EditUsername.Text <> '') and (EditPassword.Text <> '') then
    ButtonStart.Enabled := True
  else
    ButtonStart.Enabled := False;
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  GifStream, ConfStream: TResourceStream;
  ConfigFile, HistoryFile: TextFile;
  ContentString: String;
begin
  Started := False;
  ProjectCreated := False;
  EditUsername.SetFocus;
  GifStream := TResourceStream.Create(HInstance, 'GifImage_Waitting', RT_RCDATA);
  GifStream.SaveToFile(GetHomePath + '/waitting.gif');
  GifStream := TResourceStream.Create(HInstance, 'PngImage_CICD', RT_RCDATA);
  GifStream.SaveToFile(GetHomePath + '/cicd.png');
  GifStream.Free;
  if not fileexists(GetHomePath + '/Settings.conf') then
  begin
    ConfStream := TResourceStream.Create(HInstance, 'Resource_Config', RT_RCDATA);
    ConfStream.SaveToFile(GetHomePath + '/Settings.conf');
    ConfStream.Free;
  end;
  AssignFile(ConfigFile, GetHomePath + '/Settings.conf');
  Reset(ConfigFile);
  Readln(ConfigFile, ContentString);
  EditUsername.Text := ContentString;
  if EditUsername.Text <> '' then
    EditPassword.SetFocus;
  CloseFile(ConfigFile);
  if not fileexists(GetHomePath + '/History.txt') then
  begin
    ConfStream := TResourceStream.Create(HInstance, 'Resource_Config', RT_RCDATA);
    ConfStream.SaveToFile(GetHomePath + '/History.txt');
    ConfStream.Free;
  end;
  AssignFile(HistoryFile, GetHomePath + '/History.txt');
  Reset(HistoryFile);
  MemoHistory.Lines.Clear;
  while not Eof(HistoryFile) do
  begin
    Readln(HistoryFile, ContentString);
    MemoHistory.Lines.Add(ContentString);
  end;
  CloseFile(HistoryFile);
end;

procedure TFormMain.ImageWise2CClick(Sender: TObject);
begin
  TabControlMain.GotoVisibleTab(4);
  WebBrowserHelp.URL := 'http://hk.mikecrm.com/Sf9KvOR';
  WebBrowserHelp.Navigate;
end;

procedure TFormMain.TabItemContactUsClick(Sender: TObject);
begin
  WebBrowserHelp.URL := 'http://hk.mikecrm.com/Sf9KvOR';
  WebBrowserHelp.Navigate;
end;

procedure TFormMain.TabItemHelpClick(Sender: TObject);
begin
  FormMain.LabelWaitting.Visible := False;
  Application.ProcessMessages;
end;

procedure TFormMain.TabItemHistoryClick(Sender: TObject);
begin
  if Started then
    FormMain.LabelWaitting.Visible := True;
end;

procedure TFormMain.TableItemImagesClick(Sender: TObject);
begin
  FormMain.LabelWaitting.Visible := False;
end;

procedure TFormMain.TableItemLogsClick(Sender: TObject);
begin
  if Started then
    FormMain.LabelWaitting.Visible := True;
end;

procedure TFormMain.TimerCheckTimer(Sender: TObject);
begin
  CheckJobStatus;
end;

end.
