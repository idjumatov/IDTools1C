///*
//* Copyright (c) 2022, Ilham Djumatov. All rights reserved.
//* Copyrights licensed under the GNU GPLv3.
//* See the accompanying LICENSE file for terms.
//*/

// TODO: Реализовать программное копирование дерева из другого экземпляра https://infostart.ru/1c/articles/1357419/
// TODO: Реализовать возможность комментирования и раскомментирования выделенного текста или текущей строки в тексте запроса

// @strict-types
//@skip-check module-region-empty

#Region Variables

&AtClient
Var mFileName; // String - имя файла запросов
&AtClient
Var mFilePath; // String - путь к файлу запорсов
&AtClient
Var mQueryTreeRow; // FormDataStructure, FormDataCollectionItem, FormDataTreeItem - Строка дерева запросов
&AtClient
Var mQueryParametersRow; // FormDataCollectionItem - Строка параметров

#EndRegion

#Region FormEventHandlers

// On create at server.
// 
// Parameters:
//  Cancel  - Boolean - Отказ
//  StandardProcessing - Boolean - Standard processing
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
    FormTree = Items.QueryTree;
    
    // Добавление дополнительных реквизитов формы
    Attrs = New Array; // Array of FormAttribute
    Attrs.Add(New FormAttribute("PreScript",  New TypeDescription(), FormTree.Name));
    Attrs.Add(New FormAttribute("PostScript", New TypeDescription(), FormTree.Name));
    ChangeAttributes(Attrs);
    
    // Первичное заполнение дерева запросов
    Tree = FormAttributeToValue(FormTree.DataPath); // ValueTree
    Row = Tree.Rows.Add(); // ValueTreeRow
    //@skip-check wrong-string-literal-content
    Row["Name"] = DefaultNodeName();
    ValueToFormAttribute(Tree, FormTree.DataPath);
    
    // TODO: автоматически восстановить файл запросов из пользовательских настроек
    
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
    
    If Modified Then 
        
        If Exit Then 
            WarningText = NStr("
                |ru = 'Вы не сохранили файл запросов.'; 
                |en = 'You have not saved queries file.'");
            Cancel = Истина; // Система автоматически предложить остаться в системе
        Else 
            Clbk = New NotifyDescription("SaveBeforeExit", ThisObject, Parameters);
            Text = NStr("
                |ru = 'Сохранить файл запросов?';
                |en = 'Do you want to save the queries file?'");
            Mode = QuestionDialogMode.YesNoCancel; // QuestionDialogMode
            ShowQueryBox(Clbk, Text, Mode, 0);
            Cancel = Истина;
        EndIf;
        
    EndIf;
    
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// Enter code here.

#EndRegion

#Region FormTableItemsEventHandlersQueryTree

&AtClient
Procedure QueryTreeOnActivateRow(Item)
    mQueryTreeRow = Items.QueryTree.ТекущиеДанные;
EndProcedure

&AtClient
Procedure QueryTreeBeforeAddRow(Item, Cancel, Clone, Parent, IsFolder, Parameter)
    
    Cancel = Истина;
    
    SrcNode = Items.QueryTree.CurrentData; // FormDataTree, FormDataTreeItem
    If SrcNode = Undefined Then 
        SrcNode = QueryTree;
    EndIf;
    
    If Clone Then
        DstNode = SrcNode.GetParent();
        If DstNode=Undefined Then
            DstNode = QueryTree;
        EndIf;
        NewRowID = CopyTreeNode(SrcNode, DstNode);
    Else 
        NewRow = SrcNode.GetItems().Add();
        NewRow["Name"] = DefaultNodeName();
        NewRowID = NewRow.GetID();
    EndIf;
    
    If НЕ NewRowID=Undefined Then
        Items.QueryTree.ТекущаяСтрока = NewRowID;
    EndIf;
    
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersQueryParameters

// Query parameters selection.
// 
// Parameters:
//  Item - FormTable - Item
//  RowSelected - Number - Row selected
//  Field - FormField - Field
//  StandardProcessing - Boolean - Standard processing
&AtClient
Procedure QueryParametersSelection(Item, RowSelected, Field, StandardProcessing)
    
    If Field = Items.QueryTreeParametersPictureField Then 
        
        List = New ValueList; // ValueList of Number
        List.Add(0,"Δ Значение");
        List.Add(1,"≡ Список значений");
        List.Add(2,"{} Выражение");
        Clbk = New NotifyDescription("AfterChoiceFromMenu", ThisObject, Parameters);
        ShowChooseFromMenu(Clbk, List, Field);
        
    EndIf;
    
EndProcedure

&AtClient
Procedure QueryParametersOnActivateRow(Item)
    
    mQueryParametersRow = Items.QueryParameters.CurrentData;
    
EndProcedure



#Region QueryTreeParameters

&AtClient
Procedure QueryTreeParametersParameterDataOnChange(Item)
    
    Value = Undefined;
    If Not mQueryParametersRow.Property("ParameterData", Value) Then
        Raise Strings("НеРеализовано");
    EndIf;
    
    If TypeOf(Value) = Type("ValueList") Then 
        //@skip-check property-return-type
        mQueryParametersRow.ParameterType = 1;
    EndIf;
    
EndProcedure

//@skip-check property-return-type
//@skip-check invocation-parameter-type-intersect
&AtClient
Procedure QueryTreeParametersParameterDataClearing(Item, StandardProcessing)
    
    // Для выражений мы всегда используем тип строка
    If mQueryParametersRow.ParameterType = 2 Then 
        StandardProcessing = Ложь;
        mQueryParametersRow.ParameterData = "";
    Else 
        // Булево всегда очищаем
        If TypeOf(mQueryParametersRow.ParameterData) = Type("Boolean") Then 
            mQueryParametersRow.ParameterData = Undefined;
            EnableParameterTypeChoice();
        // Ссылки и другие типы приводим к пустому представлению
        ElsIf ЗначениеЗаполнено(mQueryParametersRow.ParameterData) Then 
            Type = TypeDescrFromValue(mQueryParametersRow.ParameterData);
            mQueryParametersRow.ParameterData = Type.AdjustValue();
        // Пустое представление обнуляем
        Else 
            mQueryParametersRow.ParameterData = Undefined;
            EnableParameterTypeChoice();
        EndIf;
    EndIf;
    
EndProcedure

//@skip-check property-return-type
&AtClient
Procedure QueryTreeParametersParameterDataChoiceProcessing(Item, ValueSelected, StandardProcessing)
    
    If ValueSelected = Undefined Then 
        mQueryParametersRow.ParameterType = 0;
    ElsIf ValueSelected = Type("ValueList") Then 
        mQueryParametersRow.ParameterType = 1;
    Else 
        
    EndIf;
    
EndProcedure

//@skip-check property-return-type
&AtClient
Procedure QueryTreeParametersParameterDataStartChoice(Item, ChoiceData, StandardProcessing)
    
    If mQueryParametersRow.ParameterData = Undefined Then 
        EnableParameterTypeChoice();
    Else 
        DisableParameterTypeChoice();
    EndIf;
    
EndProcedure

#EndRegion


#EndRegion

#Region FormTableItemsEventHandlersQueryResult

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
    
    If mQueryTreeRow = Undefined Then 
        ShowMessageBox(, Strings("НеВыбранЗапросВДереве"));
        Return;
    EndIf;
    
    Text = "";
    If Not mQueryTreeRow.Property("Text", Text) Then
        Raise Strings("НеРеализовано");
    EndIf;
    
    If IsBlankString(Text) Then 
        ShowMessageBox(, Strings("НеЗаполненТекстЗапроса"));
        Return;
    EndIf;
    
    GenerateAtServer(mQueryTreeRow.GetID());
    
EndProcedure

&AtClient
Procedure NewQueriesFile(Command)
    //TODO: Insert the handler content
EndProcedure

&AtClient
Procedure OpenQueriesFile(Command)
    
    DialogTitle = "Выберите файл со списком запросов";
    DialogFilter = NStr("en = 'Queries file';ru = 'Файлы запросов'") + " (*.sel)|*.sel" + "|" + 
                   NStr("en = 'All files';ru = 'Все файлы'") + " (*.*)|*.*";
    
    If VersionIsLessThan("8.3.15") Then
        Code = "
        |Clbk = New NotifyDescription(""OpenQueriesFileDialog831"", ThisObject);
        |Dialog = New FileDialog(FileDialogMode.Open);
        |Dialog.Title = DialogTitle;
        |Dialog.Filter = DialogFilter;
        |Dialog.DefaultExt = ""sel"";
        |BeginPuttingFiles(Clbk,, Dialog); // Не рекомендуется использовать, начиная с версии 8.3.15.
        |";
    Else
        Code = "
        |Dialog = New PutFilesDialogParameters;
        |Dialog.Title = DialogTitle;
        |Dialog.МножественныйВыбор = False;
        |Dialog.Filter = DialogFilter;
        |Clbk = New NotifyDescription(""OpenQueriesFileDialog835"", ThisObject);
        |BeginPutFilesToServer(Clbk,,,Dialog);
        |";
    EndIf;
#If WebClient Then
    Raise Strings("НеРеализовано");
#Else
    Execute(Code);
#EndIf
    
EndProcedure

&AtClient
Procedure SaveQueriesFile(Command)
    Address = QueriesFileAddress();
    GetFile(Address, "Запросы.sel", True);
EndProcedure

&AtClient
Procedure FillParameters(Command)
    
    If mQueryTreeRow = Undefined Then 
        Return;
    EndIf;
    
    Text = Undefined; // String
    If Not mQueryTreeRow.Property("Text", Text) Then
        Raise Strings("НеРеализовано");
    EndIf;
    
    If IsBlankString(Text) Then
        ShowMessageBox(,Strings("НеЗаполненТекстЗапроса"));
        Return;
    EndIf;
    
    Params = Undefined; // ValueTable
    If Not mQueryTreeRow.Property("Parameters", Params) Then
        Raise Strings("НеРеализовано");
    EndIf;
    ParamsFromQuery = FillParametersAtServer(Text);
    If TypeOf(ParamsFromQuery) = Type("Structure") Then 
        
        For each Item In ParamsFromQuery Do
            
            Name = Item.Key; // Имя параметра
            Type = Item.Value; // TypeDescription - Рекомендуемый тип параметра
            
            // Найдем существующий параметр
            Filter = New Structure;
            Filter.Insert("ParameterName", Name);
            Rows = Params.FindRows(Filter);
            If Rows.Count() = 0 Then 
                NewRow = Params.Add();
                //@skip-check property-return-type
                NewRow.ParameterName = Name;
            Else 
                NewRow = Rows[0];
            EndIf;
            //@skip-check property-return-type
            If Not TypeOf(NewRow.ParameterData) = Type("СписокЗначений") Then
                NewRow.ParameterData = Type.AdjustValue(NewRow.ParameterData);
            EndIf;
            
        EndDo;
        
        //Modified = True;
        
    Else 
        ShowMessageBox(,Strings("НеРеализовано"));
        Return;
    EndIf;
    
EndProcedure

&AtClient
Procedure ParamFromStringInternal(Command)
    
    Ttip = "Введите результат функции: ЗначениеВСтрокуВнутр(Запрос.Параметры.ParameterName)";
    Clbk = New NotifyDescription("ParamFromStringInternalProcessing", ThisObject, );
    ShowInputString(Clbk, "", Ttip, 0, Истина);
    
EndProcedure

&AtClient
Procedure ParamsFromStringInternal(Command)
    
    Ttip = "Введите строку ЗначениеВСтрокуВнутр(Запрос.Параметры)";
    Clbk = New NotifyDescription("ParamsFromStringInternalProcessing", ThisObject, );
    ShowInputString(Clbk, "", Ttip, 0, Истина);
    
EndProcedure

&AtClient
Procedure EditQuery(Command)
    
    If mQueryTreeRow = Undefined Then
        Return;
    EndIf;
    
    #If NOT ThickClientManagedApplication Then
    If VersionIsLessThan("8.3.5.1068") Then
        ShowMessageBox(, Strings("КонструкторЗапросаНеПоддерживается"));
        Return;
    EndIf;
    #EndIf
    
    Text = "";
    If Not mQueryTreeRow.Property("Text", Text) Then
        Raise Strings("НеРеализовано");
    EndIf;
    
    Text = TrimAll(Text);
    QWiz = New QueryWizard;
    If Not IsBlankString(Text) Then
        QWiz.Text = Text;
    EndIf;

#If ThickClientManagedApplication Then
    QWiz.AutoAppendPresentations = False;
    QWiz.DataCompositionMode = False;
    Если QWiz.DoModal() Тогда
        //@skip-check property-return-type
        mQueryTreeRow.Text = QWiz.Text;
    КонецЕсли;
#Else
    Clbk = New NotifyDescription("AfterEditingQuery", ThisObject, mQueryTreeRow);
    QWiz.Show(Clbk);
#EndIf

EndProcedure

#EndRegion

#Region Private

#Region Misc

&AtServerNoContext
Function VersionIsLessThan(Val Version)
    
    Result = CompareToCurrentVersion(Version);
    Return ?(Result = -1, Истина, Ложь);
    
EndFunction

&AtServerNoContext
Function CompareToCurrentVersion(Version)

    MinimumVersionDigits = StringToArray(Version);
    
    SystemInfo = New SystemInfo;
    CurrentVersion = SystemInfo.AppVersion;    
    CurrentVersionDigits = StringToArray(CurrentVersion);

    Для i = 0 По 3 Цикл
        
        If Number(CurrentVersionDigits[i]) = Number(MinimumVersionDigits[i]) Then
            Result = 0; 
        ElsIf Number(CurrentVersionDigits[i]) > Number(MinimumVersionDigits[i]) Then
            Result = 1; 
            Break;
        ElsIf Number(CurrentVersionDigits[i]) < Number(MinimumVersionDigits[i]) Then
            Result = -1;
            Break;
        EndIf; 
        
    EndDo; 
    
    Return Result;

EndFunction

// String to array.
// 
// Parameters:
//  Str - String - Str
//  Separator - String - Separator
// 
// Returns:
//  Array of String - Separated by Separator
&AtServerNoContext
Function StringToArray(Str, Separator = ".")

    Array = New Array;
    
    i = Find(Str, Separator);    
    While i > 0 Do
        Array.Add(Left(Str, i-1));
        Str = Mid(Str, i+1);
        i = Find(Str, Separator);
    EndDo;
        
    If StrLen(Str) > 0 Then
        Array.Add(Str);
    EndIf;
    
    Return Array;
    

EndFunction

// To JSON.
// 
// Parameters:
//  Data - Undefined - Любые сериализуемые данные
// 
// Returns:
//  String - Строка JSON
&AtServerNoContext
Function ToJSON(Знач Data)
    
    JSONWriter = New JSONWriter;
    JSONWriter.SetString();
    XDTOSerializer.WriteJSON(JSONWriter, Data, XMLTypeAssignment.Explicit);
    JSONString = JSONWriter.Close();
    Return JSONString;
    
EndFunction

// From JSON.
// 
// Parameters:
//  JSONString - String - Строка JSON
// 
// Returns:
//  Arbitrary - Любые сераилизуемые данные
&AtServerNoContext
Function FromJSON(Val JSONString)
    
    JSONReader = New JSONReader;
    JSONReader.SetString(JSONString);
    Data = XDTOSerializer.ReadJSON(JSONReader);
    JSONReader.Close();
    
    Return Data;
    
EndFunction

&AtClientAtServerNoContext
Function Strings(Val Key)
    
    Strings = New Map;
    Strings.Вставить("НеРеализовано", "Не реализовано.");
    Strings.Вставить("НеЗаполненТекстЗапроса", "Отсутствует текст запроса.");
    Strings.Вставить("НеВыбранЗапросВДереве", "Выберите запрос.");
    Strings.Вставить("НеВыбранЗапросВДереве", "Выберите запрос.");
    Strings.Вставить("КонструкторЗапросаНеПоддерживается", "Текущая версия платформы 1С:Предприятие не поддерживает запуск конструктора запросов.");
    
    Text = Strings.Get(Key);
    If Text <> Undefined Then 
        Return Text;
    EndIf;
    
    Return "";
    
EndFunction

// Добавляет строки при копировании строки дерева запросов.
// 
// Parameters:
//  Src - FormDataTree, FormDataTreeItem - Src
//  Dst - FormDataTree, FormDataTreeItem, Undefined - Dst
// 
// Returns:
//  Undefined, Number - Copy tree node
//@skip-check property-return-type
&AtClient
Function CopyTreeNode(Src, Dst)
    
    If Dst = Undefined Then
        Return Undefined;
    EndIf;
    
    NewRow = Dst.GetItems().Add();
//    FillPropertyValues(NewRow, Src);
    NewRow.Name = Src.Name;
    NewRow.Text = Src.Text;
//    НоваяСтрока.Parameters = Src.Parameters;
    
    For each Row In Src.Parameters Do
        Params = NewRow.Parameters; // FormDataCollection
        NewParam = Params.Add();
        FillPropertyValues(NewParam, Row);
    EndDo;
    For Each Item In Src.GetItems() Do
        CopyTreeNode(Item, NewRow);
    EndDo;
    
    Return NewRow.GetID();
    
EndFunction

#EndRegion

#Region PrivateFormHandlers

// Сформировать на сервере.
// 
// Parameters:
//  RowID - Число - Идентификатор строки в дереве запросов
// 
&AtServer
Procedure GenerateAtServer(RowID)
    
    QueryTreeRow = QueryTree.FindByID(RowID);
    If QueryTreeRow = Undefined Then 
        Return;
    EndIf;
    
    QueryText = QueryTreeRow.Text;
    
    QueryObject = New Query;
    FillQueryParameters(RowID, QueryObject);
    QueryObject.Text = StrReplace(QueryText, "|", "");
    
    If IsBlankString(QueryObject.Текст) Then
        Raise Strings("НеЗаполненТекстЗапроса");
    EndIf;
    
    // TODO: выполнить скрипт до выполнения запроса
    Result = QueryObject.Execute();
    // TODO: выполнить скрипт после выполнения запроса
    
    ResultTree = Result.Unload(QueryResultIteration.ByGroupsWithHierarchy);
    UpdateResultTreeAttributes(ResultTree);
    
EndProcedure

&AtServer
Procedure FillQueryParameters(RowID, QueryObject)
    
    QueryTreeRow = QueryTree.FindByID(RowID);
    If QueryTreeRow = Undefined Then 
        Return;
    EndIf;
    
    QueryArgs = QueryTreeRow.Parameters; // FormDataCollection
    For each ParametersRow In QueryArgs Do
        
        ParameterName = Undefined; // String
        ParameterType = Undefined; // Number
        ParameterData = Undefined;
        
        If Not ParametersRow.Property("ParameterName", ParameterName) Then
            Raise Strings("НеРеализовано");
        EndIf;
        If Not ParametersRow.Property("ParameterType", ParameterType) Then
            Raise Strings("НеРеализовано");
        EndIf;
        If Not ParametersRow.Property("ParameterData", ParameterData) Then
            Raise Strings("НеРеализовано");
        EndIf;
        
        If ParameterType = 2 Then
            If TypeOf(ParameterData) = Type("String") Then
                SafeMode = SafeMode();
                SetSafeMode(True);
                QueryObject.SetParameter(ParameterName, Eval(ParameterData));
                SetSafeMode(SafeMode);
            Else
                Raise "Не корректно установлен параметр.";
            EndIf;
        Else
            QueryObject.SetParameter(ParameterName, ParameterData);
        EndIf;
    EndDo;
    
EndProcedure

&AtServer
Procedure UpdateResultTreeAttributes(ValueTree)
    
    FormResultTree = Items.QueryResult;
    
    ItemsAdd = New Array; // Array of FormAttribute
    ItemsDel = New Array; // Array of String
    
    // Удаление колонок результата с формы
    Data = FormAttributeToValue(FormResultTree.DataPath);
    If TypeOf(Data) = Type("ValueTree") Then 
        For each Column In Data.Columns Do
            ItemsDel.Add(FormResultTree.DataPath + "." + Column.Name);
        EndDo;
    Else 
        Raise Strings("НеРеализовано");
    EndIf;
    
    For each Column In ValueTree.Columns Do
        // Создать реквизиты формы
        Types = Column.ValueType.Types(); // Array of TypeDescription
        For i = 0 По Types.UBound() Do
            If Types[i] = Type("PointInTime") Then
                Types[i] = New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime));
            ElsIf Types[i] = Type("Type") Then
                Types[i] = New TypeDescription("String",,New StringQualifiers(150),);
            EndIf;
        EndDo;
        Type = New TypeDescription(Types);
        ItemsAdd.Add(New FormAttribute(Column.Name, Type, FormResultTree.DataPath));
    EndDo;
    // добавляем реквизит в форму (невидимая часть, справа в редакторе форм)
    FormGroupName = FormResultTree.Name + "Group1";
    Item = Items.Find(FormGroupName);
    If Item <> Undefined Then 
        Items.Delete(Item);
    EndIf;
    ChangeAttributes(ItemsAdd, ItemsDel);
    // Вывести реквизиты на форму
    Item = Items.Add(FormGroupName, Type("FormGroup"), Items[FormResultTree.Name]);
    Item.Type = FormGroupType.ColumnGroup;
    Item.Group = ColumnsGroup.Horizontal;
    Item.FixingInTable = FixingInTable.Left;
    For each Column In ValueTree.Columns Do
        ColumnName = UniqueColumnName(FormResultTree.Name + Column.Name);
        Item2 = Items.Add(ColumnName, Type("FormField"), Items[FormGroupName]);
        Item2.Type = FormFieldType.InputField;
//        Item2.ReadOnly = True;
        Item2.DataPath = FormResultTree.DataPath + "." + Column.Name;
    EndDo;
    // Вывести данные в таблицу
    ValueToFormAttribute(ValueTree, FormResultTree.DataPath);
    
EndProcedure

// Save before exit.
// 
// Parameters:
//  Result - DialogReturnCode - Result
//  Parameters - Undefined - Parameters
&AtClient
Procedure SaveBeforeExit(Result, Parameters) Export
    If Result = DialogReturnCode.No Then
        Modified = Ложь;
        Закрыть();
        Return;
    ElsIf Result = DialogReturnCode.Cancel Then
        Return;
    EndIf;
    // TODO: реализовать сохранение
    #If WebClient Then
        // Скачать файл
    #Else
        // If файл уже выбран, то сохранить его
    #EndIf
EndProcedure

&AtServerNoContext
Function UniqueColumnName(Prefix = "")
    
    ColName = Prefix + New UUID;
    ColName = StrReplace(ColName, "-", "");
    Return ColName;
    
EndFunction

&AtClientAtServerNoContext
Function DefaultNodeName()
    Return "Запрос";
EndFunction

// After editing query.
// 
// Parameters:
//  Text - String
//  TreeItem - FormDataTreeItem
//@skip-check property-return-type
&AtClient
Procedure AfterEditingQuery(Text, TreeItem) Экспорт
    If Text = Undefined Then
        Return;
    EndIf;
    TreeItem.Text = Text;
EndProcedure

#EndRegion

#Region OpenQueriesFile

// Restore queries tree.
// 
// Parameters:
//  Address - String - Адрес временного файла
&AtServer
Procedure RestoreQueriesTree(Address)
    
    Data = GetFromTempStorage(Address); // BinaryData
    Path = GetTempFileName();
    Data.Write(Path);
    
    QueryTreeFromFile = ValueFromFile(Path); // ValueTree
    
    File = New File(Path);
    If File.Exist() Then
        DeleteFiles(Path);
    EndIf;
    
    // Для обратной совместимости в дереве из файла удалим колонки которых нету в дереве на форме
    Tree = FormAttributeToValue("QueryTree");
    For each Column In QueryTreeFromFile.Columns Do
        If Tree.Columns.Find(Column.Name) = Undefined Then 
            QueryTreeFromFile.Columns.Delete(Column);
        EndIf;
    EndDo;
    
    // заполняем дерево (реквизит формы) занчением
    ValueToFormAttribute(QueryTreeFromFile, "QueryTree");
    
    Modified = False;
    
EndProcedure

// Open queries file dialog.
// 
// Parameters:
//  Files - Array of TransferredFileDescription - Files
//  Params - Undefined - Params
&AtClient
Procedure OpenQueriesFileDialog831(Files, Params) Export 
    If Files = Undefined Then 
        Return;
    EndIf;
    For Each SelectedFileDescription In Files Do 
        //@skip-warning
        Address = SelectedFileDescription.Location;
        //@skip-warning
        RestoreQueriesTree(Address);
    EndDo;
EndProcedure

// Open queries file dialog.
// 
// Parameters:
//  Files - Array of PlacedFileDescription - Files
//  Params - Undefined - Params
&AtClient
Procedure OpenQueriesFileDialog835(Files, Params) Export 
    If Files = Undefined Then 
        Return;
    EndIf;
    For Each SelectedFileDescription In Files Do 
        //@skip-warning
        Address = SelectedFileDescription.Address;
        //@skip-warning
        RestoreQueriesTree(Address);
    EndDo;
EndProcedure

#EndRegion

#Region SaveQueriesFile

&AtServer
Function QueriesFileAddress()
    
    Path = GetTempFileName();
    
    // Запись временного файла
    Tree = FormAttributeToValue("QueryTree");
    ValueToFile(Path, Tree);
    
    // Запись файла во временное хранилище
    Data = New BinaryData(Path);
    Address = PutToTempStorage(Data, UUID);
    
    DeleteFiles(Path);
    
    Return Address;
    
EndFunction

#EndRegion

#Region ForQueryParameters

// After choice from menu.
// 
// Parameters:
//  Result - ValueListItem - Result
//  Parameters - Undefined - Parameters
//@skip-check property-return-type
//@skip-check dynamic-access-method-not-found
//@skip-check invocation-parameter-type-intersect
&AtClient
Procedure AfterChoiceFromMenu(Result, Parameters) Export
    
    If Result = Undefined Then 
        Return;
    EndIf;
    
    ParamType = Result.Value;
    If mQueryParametersRow.ParameterType = ParamType Then 
        Return;
    EndIf;
    
    // Установка атрибута
    mQueryParametersRow.ParameterType = ParamType;
    
    // Преобразование значения
    If ParamType = 0 Then // Значение
        If TypeOf(mQueryParametersRow.ParameterData) = Type("ValueList") Then 
            If mQueryParametersRow.ParameterData.Количество() > 0 Then 
                mQueryParametersRow.ParameterData = mQueryParametersRow.ParameterData[0].Значение;
                //Types = TypeDescrFromValue(мПараметр.ParameterData);
                //Items.QueryTreeParametersParameterData.ОграничениеТипа = Types;
            Else 
                //Items.QueryTreeParametersParameterData.ОграничениеТипа = New ОписаниеТипов;
            EndIf;
        Else 
            //Items.QueryTreeParametersParameterData.ОграничениеТипа = New ОписаниеТипов;
        EndIf;
    ElsIf ParamType = 1 Then // Список
        List = New ValueList;
        Types = TypeDescrFromValue(mQueryParametersRow.ParameterData);
        List.ValueType = Types;
        //@skip-check typed-value-adding-to-untyped-collection
        List.Add(mQueryParametersRow.ParameterData);
        mQueryParametersRow.ParameterData = List;
        //Types = TypeDescrFromValue(Список);
        //Items.QueryTreeParametersParameterData.ОграничениеТипа = Types;
    ElsIf ParamType = 2 Then // Выражение
        Value = "";
        Type = TypeDescrFromValue(Value);
        mQueryParametersRow.ParameterData = Type.AdjustValue(mQueryParametersRow.ParameterData);
    Else 
        Raise Strings("НеРеализовано");
    EndIf;
    
EndProcedure

&AtServerNoContext
Function FillParametersAtServer(QueryText)
    
    Query = New Query(QueryText);
    QueryParams = Query.FindParameters();
    
    Params = New Structure;
    For each Param In QueryParams Do
        Name =  Param.Name;
        Type =  Param.ValueType;
        Params.Insert(Name, Type);
    EndDo;
    
    Return Params;
    
EndFunction

&AtClient
Function TypeDescrFromValue(Value)
    
    ArrayOfTypes = New Array; // Array of Type
    ArrayOfTypes.Add(TypeOf(Value));
    TypeDescription = New TypeDescription(ArrayOfTypes);
    Return TypeDescription;
    
EndFunction 

&AtClient
Procedure DisableParameterTypeChoice()
    Items.QueryTreeParametersParameterData.ChooseType = False;
EndProcedure

&AtClient
Procedure EnableParameterTypeChoice()
    Items.QueryTreeParametersParameterData.ChooseType = True;
EndProcedure

#EndRegion

#Region ParamFromStringInternal

// Params from string internal.
// 
// Parameters:
//  Text - String - Text
// 
// Returns:
//  ValueList of Arbitrary, Arbitrary - Params from string internal
&AtServerNoContext
Function ParamFromStringInternalAtServerNoContext(Text)
    
    Value = ValueFromStringInternal(Text);
    
    Result = Undefined;
    
    If TypeOf(Value) = Type("Array") Then 
        Result = New ValueList;
        For each CurrentValue In Value Do
            //@skip-check typed-value-adding-to-untyped-collection
            Result.Add(CurrentValue);
        EndDo;
    Else 
        Result = Value;
    EndIf;
    
    Return Result;
    
EndFunction

// После ввода строки параметра.
// 
// Parameters:
//  Text - String - Text
//  Param - Undefined - Param
&AtClient
Procedure ParamFromStringInternalProcessing(Text, Param) Export
    If Not Text = Undefined Then
        
        ParameterData = ParamFromStringInternalAtServerNoContext(Text);
        //@skip-check property-return-type
        mQueryParametersRow.ParameterData = ParameterData
        
    EndIf;
EndProcedure

// Params from string internal processing.
// 
// Parameters:
//  Text - String - Text
//  Params - Undefined - Params
//@skip-check property-return-type
//@skip-check dynamic-access-method-not-found
//@skip-check invocation-parameter-type-intersect
&AtClient
Procedure ParamsFromStringInternalProcessing(Text, Params) Export
    
    // TODO: спросить, можно ли очистить список параметров
    If Text = Undefined Then
        Return;
    EndIf;
    ParameterData = ParamFromStringInternalAtServerNoContext(Text);
    If TypeOf(ParameterData) <> Type("Структура") Then 
        ShowMessageBox(, "Нужно выгрузить ЗначениеВСтрокуВнутр(Запрос.Параметры)");
        Return;
    Else 
        mQueryTreeRow.Parameters.Clear();
        For each Item In ParameterData Do
            NewRow = mQueryTreeRow.Parameters.Add(); // FormDataCollectionItem
            NewRow.ParameterName = Item.Ключ;
            If TypeOf(Item.Значение) = Type("Массив") Then 
                List = New СписокЗначений;
                List.ЗагрузитьЗначения(Item.Значение);
                NewRow.ParameterData = List;
            Else 
                NewRow.ParameterData = Item.Значение;
            EndIf;
        EndDo;
    EndIf;
    
EndProcedure

#EndRegion

#EndRegion
