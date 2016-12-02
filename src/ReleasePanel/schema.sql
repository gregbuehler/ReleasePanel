USE [master]
GO
/****** Object:  Database [rpanel]    Script Date: 12/1/2016 9:22:32 AM ******/
CREATE DATABASE [rpanel]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'rpanel', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\rpanel.mdf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'rpanel_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\rpanel_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [rpanel] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [rpanel].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [rpanel] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [rpanel] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [rpanel] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [rpanel] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [rpanel] SET ARITHABORT OFF 
GO
ALTER DATABASE [rpanel] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [rpanel] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [rpanel] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [rpanel] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [rpanel] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [rpanel] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [rpanel] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [rpanel] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [rpanel] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [rpanel] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [rpanel] SET  DISABLE_BROKER 
GO
ALTER DATABASE [rpanel] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [rpanel] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [rpanel] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [rpanel] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [rpanel] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [rpanel] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [rpanel] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [rpanel] SET RECOVERY FULL 
GO
ALTER DATABASE [rpanel] SET  MULTI_USER 
GO
ALTER DATABASE [rpanel] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [rpanel] SET DB_CHAINING OFF 
GO
ALTER DATABASE [rpanel] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [rpanel] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'rpanel', N'ON'
GO
USE [rpanel]
GO
/****** Object:  UserDefinedTableType [dbo].[IssueLabelsType]    Script Date: 12/1/2016 9:22:33 AM ******/
CREATE TYPE [dbo].[IssueLabelsType] AS TABLE(
	[issue] [bigint] NULL,
	[label] [bigint] NULL
)
GO
/****** Object:  StoredProcedure [dbo].[GetProjectsReleasesAndIssues]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetProjectsReleasesAndIssues]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
	    p.*,
	    r.*,
	    i.*
    FROM
	    GithubProjects p
    INNER JOIN
	    GithubReleases r on r.project = p.id
    INNER JOIN
	    GithubIssues i on i.release = r.id
END

GO
/****** Object:  StoredProcedure [dbo].[SyncGithubIssueLabels]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SyncGithubIssueLabels]
	@IssueLabels IssueLabelsType READONLY
AS
MERGE dbo.GithubIssueLabels AS t
USING @IssueLabels AS s
ON (t.issue = s.issue AND t.label = s.label)
WHEN NOT MATCHED BY TARGET
    THEN INSERT(issue, label) VALUES( issue , label)
WHEN NOT MATCHED BY SOURCE
    THEN DELETE;

GO
/****** Object:  StoredProcedure [dbo].[UpsertIssue]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpsertIssue] 
	@issueId bigint,
	@releaseId bigint,
	@title nvarchar(255),
	@createdAt nvarchar(25) = '',
	@closedAt nvarchar(25) = '',
	@updatedAt nvarchar(25) = '',
	@dueAt nvarchar(25) = '',
	@due_on nvarchar(25) = '',
	@body text = '',
	@state nvarchar(50) = '',
	@link nvarchar(255) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    MERGE dbo.GithubIssues as t
    USING (SELECT @issueId as id) as s
    ON t.id = s.id
    WHEN MATCHED THEN UPDATE SET
        t.release = @releaseId,
        t.title = @title,
        t.createdAt = @createdAt,
        t.closedAt = @closedAt,
        t.updatedAt = @updatedAt,
        t.body = @body, -- empty body, needs to escape quotes
        t.state = @state,
        t.link = @link
    WHEN NOT MATCHED THEN INSERT (
        id,
        release,
        title,
        createdAt,
        closedAt,
        updatedAt,
        body,
        state,
        link
    ) VALUES (
        s.id,
        @releaseId,
        @title,
        @createdAt,
        @closedAt,
        @updatedAt,
        @body, --empty body, needs to escape quotes
        @state,
        @link
    );
END

GO
/****** Object:  StoredProcedure [dbo].[UpsertLabels]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpsertLabels]
	@labelId bigint,
	@labelName nvarchar(50)
AS
	MERGE dbo.GithubLabels as t
	USING (SELECT @labelId as id) as s
	ON t.id = s.id
	WHEN MATCHED THEN UPDATE SET
		t.name = @labelName
	WHEN NOT MATCHED THEN INSERT (
		id,
		name
	) VALUES (
		@labelId,
		@labelName
	);

GO
/****** Object:  StoredProcedure [dbo].[UpsertRelease]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpsertRelease]
	@releaseId bigint,
	@title nvarchar(255) = '',
	@createdAt nvarchar(25) = '',
	@closedAt nvarchar(25) = '',
	@updatedAt nvarchar(25) = '',
	@dueAt nvarchar(25) = '',
	@due_on nvarchar(25) = '',
	@state nvarchar(50) = '',
	@link nvarchar(255) = ''
AS
BEGIN
	SET NOCOUNT ON;

    MERGE dbo.GithubReleases as t
    USING (SELECT @releaseId as id) as s
    ON t.id = s.id
    WHEN MATCHED THEN UPDATE SET
        t.title = @title,
        t.createdAt = @createdAt,
        t.closedAt = @closedAt,
        t.updatedAt = @updatedAt,
        t.dueAt = @dueAt,
        t.state = @state,
        t.link = @link
    WHEN NOT MATCHED THEN INSERT (
        id, 
        title,
        createdAt,
        closedAt,
        updatedAt,
        dueAt,
        state,
        link
    ) VALUES (
        s.id, 
        @title,
        @createdAt,
        @closedAt,
        @updatedAt,
        @dueAt,
        @state,
        @link
    );
END

GO
/****** Object:  Table [dbo].[GithubIssueLabels]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GithubIssueLabels](
	[issue] [bigint] NOT NULL,
	[label] [bigint] NOT NULL,
 CONSTRAINT [PK_GithubIssueLabels_1] PRIMARY KEY CLUSTERED 
(
	[issue] ASC,
	[label] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GithubIssueParticipants]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GithubIssueParticipants](
	[issue] [bigint] NOT NULL,
	[participant] [bigint] NOT NULL,
 CONSTRAINT [PK_GithubIssueParticipants_1] PRIMARY KEY CLUSTERED 
(
	[issue] ASC,
	[participant] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GithubIssues]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GithubIssues](
	[id] [bigint] NOT NULL,
	[title] [nvarchar](255) NOT NULL,
	[createdAt] [datetime] NULL,
	[closedAt] [datetime] NULL,
	[updatedAt] [datetime] NULL,
	[body] [text] NULL,
	[state] [nvarchar](50) NULL,
	[link] [nvarchar](255) NULL,
	[release] [bigint] NOT NULL,
 CONSTRAINT [PK_GithubChanges] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GithubLabels]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GithubLabels](
	[id] [bigint] NOT NULL,
	[name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_GithubLabels] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GithubProjects]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GithubProjects](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_GithubProjects] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GithubReleases]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GithubReleases](
	[id] [bigint] NOT NULL,
	[title] [nvarchar](255) NOT NULL,
	[createdAt] [datetime] NULL,
	[closedAt] [datetime] NULL,
	[updatedAt] [datetime] NULL,
	[dueAt] [datetime] NULL,
	[state] [nvarchar](50) NULL,
	[link] [nvarchar](255) NULL,
	[project] [bigint] NULL,
 CONSTRAINT [PK_GithubReleases] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Participants]    Script Date: 12/1/2016 9:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Participants](
	[id] [bigint] NOT NULL,
	[githubUsername] [nvarchar](255) NULL,
	[pivotalUsername] [nvarchar](255) NULL,
	[callingUsername] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_Participants] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_GithubChanges]    Script Date: 12/1/2016 9:22:33 AM ******/
CREATE NONCLUSTERED INDEX [IX_GithubChanges] ON [dbo].[GithubIssues]
(
	[release] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[GithubIssueLabels]  WITH CHECK ADD  CONSTRAINT [FK_GithubIssueLabels_GithubIssues] FOREIGN KEY([issue])
REFERENCES [dbo].[GithubIssues] ([id])
GO
ALTER TABLE [dbo].[GithubIssueLabels] CHECK CONSTRAINT [FK_GithubIssueLabels_GithubIssues]
GO
ALTER TABLE [dbo].[GithubIssueLabels]  WITH CHECK ADD  CONSTRAINT [FK_GithubIssueLabels_GithubLabels] FOREIGN KEY([label])
REFERENCES [dbo].[GithubLabels] ([id])
GO
ALTER TABLE [dbo].[GithubIssueLabels] CHECK CONSTRAINT [FK_GithubIssueLabels_GithubLabels]
GO
ALTER TABLE [dbo].[GithubIssueParticipants]  WITH CHECK ADD  CONSTRAINT [FK_GithubIssueParticipants_GithubIssues] FOREIGN KEY([issue])
REFERENCES [dbo].[GithubIssues] ([id])
GO
ALTER TABLE [dbo].[GithubIssueParticipants] CHECK CONSTRAINT [FK_GithubIssueParticipants_GithubIssues]
GO
ALTER TABLE [dbo].[GithubIssueParticipants]  WITH CHECK ADD  CONSTRAINT [FK_GithubIssueParticipants_Participants] FOREIGN KEY([participant])
REFERENCES [dbo].[Participants] ([id])
GO
ALTER TABLE [dbo].[GithubIssueParticipants] CHECK CONSTRAINT [FK_GithubIssueParticipants_Participants]
GO
ALTER TABLE [dbo].[GithubIssues]  WITH CHECK ADD  CONSTRAINT [FK_GithubChanges_GithubReleases] FOREIGN KEY([release])
REFERENCES [dbo].[GithubReleases] ([id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GithubIssues] CHECK CONSTRAINT [FK_GithubChanges_GithubReleases]
GO
USE [master]
GO
ALTER DATABASE [rpanel] SET  READ_WRITE 
GO
