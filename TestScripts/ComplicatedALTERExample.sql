CREATE TABLE [dbo].[SometAble](
	[PaymentInvoiceMatchingMethodId] [int] NOT NULL,
	[Code] [varchar](20) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Description] [varchar](255) NOT NULL,
	[CreateDate] [datetime2](7) NULL,
	[CreateBy] [varchar](255) NULL,
	[ModifyDate] [datetime2](7) NULL,
	[ModifyBy] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[PaymentInvoiceMatchingMethodId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[SometAble] ADD  DEFAULT (sysdatetime()) FOR [CreateDate]
GO

ALTER TABLE [dbo].[SometAble] ADD somecolumn int not null
GO