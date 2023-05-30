/*----------------------------------
   UindexWeb数据库表结构描述文件

  注意:如果你的SQLserver安装目录和
这里默认的不一样,请自己修改数据库文
件路径.例外,如果您曾创建UindexWeb数
据库,请先删除.
----------------------------------*/
Create database UindexWeb
on
Primary(name=soWeb_data,
filename='c:\Program files\microsoft sql server\mssql\data\UindexWeb.mdf',
size=500MB,
MAXSIZE=2000MB,
FileGrowth=2MB
)
Log on(
name=soWeb_log,
filename='c:\Program files\microsoft sql server\mssql\data\UindexWeb.ldf',
size=50MB,
Maxsize=1000MB,
FileGrowth=25%)
Collate Chinese_PRC_CI_AS
go
use UindexWeb
go
CREATE TABLE UindexWeb_BadWord
(
   BWId int
        IDENTITY(1,1)
        PRIMARY KEY CLUSTERED,
   BWString varchar(255) NOT NULL UNIQUE,
)
go
CREATE TABLE UindexWeb_FobidenUrl
(
   FBUId  int
        IDENTITY(1,1)
        PRIMARY KEY CLUSTERED,
   FBUString varchar(255) NOT NULL UNIQUE,
)
go
CREATE TABLE UindexWeb_WebPage
(
   WPId  int
        IDENTITY(1,1)
        PRIMARY KEY CLUSTERED,
   WPTitle  varchar(255),
   WPRealTitle  varchar(255),
   WPCopyRight varchar(255),
   WPAuthor  varchar(255),
   WPDevelopTool  varchar(255),
   WPKeyword  varchar(255),
   WPDiscription varchar(255),
   WPHaveFile  int DEFAULT 0,
   WPHaveLink int DEFAULT 0,
   WPContent ntext,
   WPUrl varchar(255) NOT NULL UNIQUE,
   WPSiteId int DEFAULT 0,
   WPBadWord int DEFAULT 0,
   WPSignature varchar(255) NOT NULL UNIQUE,
)
go
CREATE TABLE UindexWeb_FileList
(
   FLId  int
        IDENTITY(1,1)
        PRIMARY KEY CLUSTERED,
   FLUrl varchar(255) NOT NULL UNIQUE,
   FLComment   ntext,
   FLSiteId   int DEFAULT 0,
   FLWebpage   int DEFAULT 0,
)
go
CREATE TABLE UindexWeb_WebUrl
(
   WUId  int
        IDENTITY(1,1)
        PRIMARY KEY CLUSTERED,
   WUUrl varchar(255) NOT NULL UNIQUE,
   WUStatus   int DEFAULT 0,
   WUSiteId   int DEFAULT 0,
   WUSize     int DEFAULT 0,
   WUParent   int DEFAULT 0,
)
go
CREATE TABLE UindexWeb_Entry
(
   SEId  int
        IDENTITY(1,1)
        PRIMARY KEY CLUSTERED,
   SERoot  varchar(255) NOT NULL UNIQUE,
   SEEntryPoint  varchar(255) NOT NULL UNIQUE,
   SEGroup int DEFAULT 0,
   SEStatus int DEFAULT 0,
   SEMaxpage int DEFAULT 0,
   SEForbiden ntext,
   SEBadwords ntext,
   SEClipmax int DEFAULT 0,
)
go
