drop database fdis;
create database fdis;
USE `fdis`;

CREATE TABLE `AreaDescription_ElementType`(
	`AreaDescId` int NOT NULL,
	`AreaDescModuleId` int NOT NULL,
	`ElementTypeId` INT NOT NULL,
 CONSTRAINT `PK_AreaDescription_ElementType` PRIMARY KEY 
(
	`AreaDescId` ASC,
	`AreaDescModuleId` ASC,
	`ElementTypeId` ASC
)
) 
;
/****** Object:  Table `AreaDescriptions`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `AreaDescriptions`(
	`Id` int AUTO_INCREMENT NOT NULL,
	`ModuleId` int NOT NULL,
	`Name` varchar(255) NOT NULL,
	`Abbreviation` char(10) NOT NULL,
	`Active` TINYINT(1) NOT NULL,
 CONSTRAINT `PK_AreaDescriptions` PRIMARY KEY 
(
	`Id` ASC,
	`ModuleId` ASC
)
)  
;
/****** Object:  Table `Areas`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Areas`(
	`Id` int AUTO_INCREMENT NOT NULL,
	`OrNumber` int NOT NULL,
	`IsActive` TINYINT(1) NOT NULL,
	`QrCode` varchar(255) NULL,
	`CustomerId` int NOT NULL,
	`Description` varchar(255) NOT NULL,
 CONSTRAINT `PK_Areas` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `aspnet_Applications`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `aspnet_Applications`(
	`ApplicationName` varchar(256) NOT NULL,
	`LoweredApplicationName` varchar(256) NOT NULL,
	`ApplicationId` CHAR(36) NOT NULL,
	`Description` varchar(256) NULL
) 
;
/****** Object:  Table `aspnet_Membership`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `aspnet_Membership`(
	`ApplicationId` CHAR(36) NOT NULL,
	`UserId` CHAR(36) NOT NULL,
	`Password` varchar(128) NOT NULL,
	`PasswordFormat` int NOT NULL,
	`PasswordSalt` varchar(128) NOT NULL,
	`MobilePIN` varchar(16) NULL,
	`Email` varchar(256) NULL,
	`LoweredEmail` varchar(256) NULL,
	`PasswordQuestion` varchar(256) NULL,
	`PasswordAnswer` varchar(128) NULL,
	`IsApproved` TINYINT(1) NOT NULL,
	`IsLockedOut` TINYINT(1) NOT NULL,
	`CreateDate` datetime NOT NULL,
	`LastLoginDate` datetime  NOT NULL,
	`LastPasswordChangedDate` datetime  NOT NULL,
	`LastLockoutDate` datetime  NOT NULL,
	`FailedPasswordAttemptCount` int NOT NULL,
	`FailedPasswordAttemptWindowStart` datetime  NOT NULL,
	`FailedPasswordAnswerAttemptCount` int NOT NULL,
	`FailedPasswordAnswerAttemptWindowStart` datetime  NOT NULL,
	`Comment` text NULL
)  
;
/****** Object:  Table `aspnet_Paths`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `aspnet_Paths`(
	`ApplicationId` CHAR(36) NOT NULL,
	`PathId` CHAR(36) NOT NULL,
	`Path` varchar(256) NOT NULL,
	`LoweredPath` varchar(256) NOT NULL
) 
;
/****** Object:  Table `aspnet_PersonalizationAllUsers`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `aspnet_PersonalizationAllUsers`(
	`PathId` CHAR(36) NOT NULL,
	`PageSettings` varchar(100) NOT NULL,
	`LastUpdatedDate` datetime  NOT NULL,
PRIMARY KEY 
(
	`PathId` ASC
)
)  
;
/****** Object:  Table `aspnet_PersonalizationPerUser`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `aspnet_PersonalizationPerUser`(
	`Id` INT NOT NULL,
	`PathId` CHAR(36) NULL,
	`UserId` CHAR(36) NULL,
	`PageSettings` varchar(100) NOT NULL,
	`LastUpdatedDate` datetime  NOT NULL
)  
;
/****** Object:  Table `aspnet_Profile`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `aspnet_Profile`(
	`UserId` CHAR(36) NOT NULL,
	`PropertyNames` text NOT NULL,
	`PropertyValuesString` text NOT NULL,
	`PropertyValuesBinary` varchar(100) NOT NULL,
	`LastUpdatedDate` datetime  NOT NULL,
PRIMARY KEY 
(
	`UserId` ASC
)
)  
;
/****** Object:  Table `aspnet_Roles`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `aspnet_Roles`(
	`ApplicationId` CHAR(36) NOT NULL,
	`RoleId` CHAR(36) NOT NULL,
	`RoleName` varchar(256) NOT NULL,
	`LoweredRoleName` varchar(256) NOT NULL,
	`Description` varchar(256) NULL
) 
;
/****** Object:  Table `aspnet_SchemaVersions`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `aspnet_SchemaVersions`(
	`Feature` varchar(128) NOT NULL,
	`CompatibleSchemaVersion` varchar(128) NOT NULL,
	`IsCurrentVersion` TINYINT(1) NOT NULL,
PRIMARY KEY 
(
	`Feature` ASC,
	`CompatibleSchemaVersion` ASC
)
) 
;
/****** Object:  Table `aspnet_Users`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `aspnet_Users`(
	`ApplicationId` CHAR(36) NOT NULL,
	`UserId` CHAR(36) NOT NULL,
	`UserName` varchar(256) NOT NULL,
	`LoweredUserName` varchar(256) NOT NULL,
	`MobileAlias` varchar(16) NULL,
	`IsAnonymous` TINYINT(1) NOT NULL,
	`LastActivityDate` datetime  NOT NULL
) 
;
/****** Object:  Table `aspnet_UsersInRoles`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `aspnet_UsersInRoles`(
	`UserId` CHAR(36) NOT NULL,
	`RoleId` CHAR(36) NOT NULL,
PRIMARY KEY 
(
	`UserId` ASC,
	`RoleId` ASC
)
) 
;
/****** Object:  Table `aspnet_WebEvent_Events`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `aspnet_WebEvent_Events`(
	`EventId` char(32) NOT NULL,
	`EventTimeUtc` datetime  NOT NULL,
	`EventTime` datetime  NOT NULL,
	`EventType` varchar(256) NOT NULL,
	`EventSequence` decimal(19, 0) NOT NULL,
	`EventOccurrence` decimal(19, 0) NOT NULL,
	`EventCode` int NOT NULL,
	`EventDetailCode` int NOT NULL,
	`Message` varchar(1024) NULL,
	`ApplicationPath` varchar(256) NULL,
	`ApplicationVirtualPath` varchar(256) NULL,
	`MachineName` varchar(256) NOT NULL,
	`RequestUrl` varchar(1024) NULL,
	`ExceptionType` varchar(256) NULL,
	`Details` text NULL,
PRIMARY KEY 
(
	`EventId` ASC
)
)  
;
/****** Object:  Table `Attachments`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Attachments`(
	`Id` INT NOT NULL,
	`DataLocation` varchar(100) NOT NULL,
	`ContentType` varchar(100) NOT NULL,
	`AttachmentFileName` varchar(100) NOT NULL,
 CONSTRAINT `PK_Attachments` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `AuditAuditor`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `AuditAuditor`(
	`AuditorId` CHAR(36) NOT NULL,
	`AuditId` CHAR(36) NOT NULL,
 CONSTRAINT `PK_AuditAuditor` PRIMARY KEY 
(
	`AuditorId` ASC,
	`AuditId` ASC
)
) 
;
/****** Object:  Table `AuditRemarks`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `AuditRemarks`(
	`Id` INT NOT NULL,
	`AuditId` CHAR(36) NOT NULL,
	`RemarkText` varchar(255) NULL,
	`RemarkImage` CHAR(36) NULL,
	`FormId` CHAR(36) NULL,
 CONSTRAINT `PK_AuditRemarks` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `Audits`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Audits`(
	`AuditCode` bigint NOT NULL,
	`Date` datetime  NOT NULL,
	`IsActive` TINYINT(1) NOT NULL,
	`IsDone` TINYINT(1) NULL,
	`Id` int auto_increment  NOT NULL,
	`Type` varchar(10) NULL,
	`NameClient_Id` CHAR(36) NOT NULL,
	`LocationClient_Id` CHAR(36) NOT NULL,
	`PresentClient` varchar(255) NULL,
	`Attn` varchar(255) NULL,
	`week` int NULL,
	`LastControlDate` datetime  NULL,
	`Activate` TINYINT(1) NOT NULL,
	`LocationManagerSignImage` CHAR(36) NULL,
	`AuditHash` varchar(64) NULL,
 CONSTRAINT `PK_Audits` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `Audits_HAudit`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Audits_HAudit`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Audits_HAudit` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Audits_KAudit`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Audits_KAudit`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Audits_KAudit` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Audits_QAudit`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Audits_QAudit`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Audits_QAudit` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Branches`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Branches`(
	`Id` int auto_increment  NOT NULL,
	`BranchName` varchar(255) NOT NULL,
 CONSTRAINT `PK_Branches` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `BuildingFloor`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `BuildingFloor`(
	`IdFloor` CHAR(36) NOT NULL,
	`IdBuilding` CHAR(36) NOT NULL,
 CONSTRAINT `PK_BuildingFloor` PRIMARY KEY 
(
	`IdFloor` ASC,
	`IdBuilding` ASC
)
) 
;
/****** Object:  Table `Buildings`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Buildings`(
	`Id` int auto_increment  NOT NULL,
	`Name` varchar(255) NOT NULL,
	`Size` int NOT NULL,
	`ClientId` CHAR(36) NOT NULL,
	`Region` varchar(255) NULL,
	`City` varchar(255) NULL,
	`Address` varchar(255) NULL,
	`ContactPerson` varchar(255) NULL,
	`Activate` TINYINT(1) NOT NULL,
	`Email` varchar(100) NULL,
 CONSTRAINT `PK_Buildings` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `Buildings_HBuilding`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Buildings_HBuilding`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Buildings_HBuilding` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Buildings_KBuilding`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Buildings_KBuilding`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Buildings_KBuilding` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Buildings_QBuilding`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Buildings_QBuilding`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Buildings_QBuilding` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `BuildingSizeScale`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `BuildingSizeScale`(
	`Id` INT auto_increment  NOT NULL,
	`minValue` int NULL,
	`minInclude` TINYINT(1) NULL,
	`maxValue` int NULL,
	`maxInclude` TINYINT(1) NULL,
 CONSTRAINT `PK_BuildingSizeScale` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Categories`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Categories`(
	`Id` INT auto_increment  NOT NULL,
	`CategoryNameAbv` varchar(255) NULL,
	`IsFixed` TINYINT(1) NULL,
	`CategoryName` varchar(255) NOT NULL,
	`SortOrder` int NOT NULL,
 CONSTRAINT `PK_Categories` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `Categories_HCategory`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Categories_HCategory`(
	`Id` INT NOT NULL,
	`AreaType` int NOT NULL,
 CONSTRAINT `PK_Categories_HCategory` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Categories_KCategory`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Categories_KCategory`(
	`ApprovedLimit` int NOT NULL,
	`FixedElementNumber` int NOT NULL,
	`Id` INT NOT NULL,
	`MaxNumberErrorsPerUnit` int NOT NULL,
 CONSTRAINT `PK_Categories_KCategory` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Categories_QCategory`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Categories_QCategory`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Categories_QCategory` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Category_AreaDescription`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Category_AreaDescription`(
	`CategoryId` CHAR(36) NOT NULL,
	`AreaDescId` int NOT NULL,
	`AreaDescModuleId` int NOT NULL,
 CONSTRAINT `PK_Category_AreaDescription` PRIMARY KEY 
(
	`CategoryId` ASC,
	`AreaDescId` ASC,
	`AreaDescModuleId` ASC
)
) 
;
/****** Object:  Table `CategoryFloor`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `CategoryFloor`(
	`Categories_Id` CHAR(36) NOT NULL,
	`Floors_Id` CHAR(36) NOT NULL
) 
;
/****** Object:  Table `Client_Category`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Client_Category`(
	`ClientId` CHAR(36) NOT NULL,
	`CategoryId` CHAR(36) NOT NULL,
 CONSTRAINT `PK_Client_Category` PRIMARY KEY 
(
	`ClientId` ASC,
	`CategoryId` ASC
)
) 
;
/****** Object:  Table `ClientAuditor`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ClientAuditor`(
	`AuditorId` CHAR(36) NOT NULL,
	`ClientId` CHAR(36) NOT NULL,
 CONSTRAINT `PK_ClientAuditor` PRIMARY KEY 
(
	`AuditorId` ASC,
	`ClientId` ASC
)
) 
;
/****** Object:  Table `ClientModule`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ClientModule`(
	`Clients_Id` CHAR(36) NOT NULL,
	`Modules_Id` int NOT NULL,
	`CreateNewAuditAutomatically` TINYINT(1) NULL
) 
;
/****** Object:  Table `ConstantSizeCategory`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ConstantSizeCategory`(
	`Id` INT auto_increment  NOT NULL,
	`CategoryId` CHAR(36) NULL,
	`BuildingSizeScaleId` CHAR(36) NULL,
	`MinimunSizeRange` int NULL,
	`MaximunSizeRange` int NULL,
	`ApprovedLimit` int NULL,
 CONSTRAINT `PK_ConstantSizeCategory` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Country`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Country`(
	`Id` INT auto_increment  NOT NULL,
	`CountryName` varchar(255) NULL,
	`CountryCode` char(10) NOT NULL,
 CONSTRAINT `PK_Country` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `Customers`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Customers`(
	`Id` int AUTO_INCREMENT NOT NULL,
	`Name` varchar(255) NOT NULL,
	`Email` varchar(255) NULL,
	`Phone` varchar(255) NULL,
	`Mobile` varchar(255) NULL,
	`Fax` varchar(255) NULL,
	`Address` varchar(255) NULL,
	`ZipCode` varchar(255) NULL,
	`State` varchar(255) NULL,
	`IsActive` TINYINT(1) NOT NULL,
	`ClientId` CHAR(36) NOT NULL,
	`CountryId` CHAR(36) NULL,
 CONSTRAINT `PK_Customers` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `Customers_DCustomer`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Customers_DCustomer`(
	`Id` int NOT NULL,
 CONSTRAINT `PK_Customers_DCustomer` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Customers_HCustomer`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Customers_HCustomer`(
	`Id` int NOT NULL,
 CONSTRAINT `PK_Customers_HCustomer` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `DateDesviationGenerated`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `DateDesviationGenerated`(
	`Id` INT auto_increment  NOT NULL,
	`Date` datetime  NULL,
 CONSTRAINT `PK_DateDesviationGenerated` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `DeliveryChecks`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `DeliveryChecks`(
	`Id` bigint AUTO_INCREMENT NOT NULL,
	`Date` datetime  NOT NULL,
	`PerformerId` CHAR(36) NOT NULL,
	`AreaId` int NOT NULL,
 CONSTRAINT `PK_DeliveryChecks` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `DesviationValue`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `DesviationValue`(
	`DesviationValue` float NULL,
	`RatingID` CHAR(36) NULL,
	`DateID` CHAR(36) NULL,
	`Id` INT auto_increment  NOT NULL,
 CONSTRAINT `PK_DesviationValue_1` PRIMARY KEY 
(
	`ID` ASC
)
) 
;
/****** Object:  Table `Element`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Element`(
	`Id` INT NOT NULL,
	`ElementLabel` varchar(255) NOT NULL,
	`ElementStatus` TINYINT(1) NULL,
 CONSTRAINT `PK_Element` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `ElementAudit`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ElementAudit`(
	`IdElement` CHAR(36) NOT NULL,
	`IdAudit` CHAR(36) NOT NULL,
	`ElementAuditStatus` CHAR(36) NOT NULL,
	`ElementAuditComment` varchar(255) NULL,
 CONSTRAINT `PK_ElementAudit` PRIMARY KEY 
(
	`IdElement` ASC,
	`IdAudit` ASC
)
)  
;
/****** Object:  Table `ElementClient`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ElementClient`(
	`IdElement` CHAR(36) NOT NULL,
	`IdClient` CHAR(36) NOT NULL,
	`ElementClientStatus` TINYINT(1) NOT NULL,
 CONSTRAINT `PK_ElementClient` PRIMARY KEY 
(
	`IdElement` ASC,
	`IdClient` ASC
)
) 
;
/****** Object:  Table `ElementStatusValue`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ElementStatusValue`(
	`Id` INT NOT NULL,
	`ElementStatusValueCode` char(10) NOT NULL,
	`ElementStatusValueText` varchar(255) NOT NULL,
	`SortOrder` int NULL,
 CONSTRAINT `PK_ElementStatusValue` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `ElementType`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ElementType`(
	`ElementTypeId` INT auto_increment  NOT NULL,
	`ElementTypeValue` varchar(255) NULL,
	`SortOrder` int NOT NULL,
 CONSTRAINT `PK_ElementType` PRIMARY KEY 
(
	`ElementTypeId` ASC
)
)  
;
/****** Object:  Table `ElementType_HElementType`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ElementType_HElementType`(
	`ElementTypeId` INT NOT NULL,
	`ElementTypeParent` CHAR(36) NULL,
 CONSTRAINT `PK_ElementType_HElementType` PRIMARY KEY 
(
	`ElementTypeId` ASC
)
) 
;
/****** Object:  Table `ElementType_KElementType`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ElementType_KElementType`(
	`ElementTypeId` INT NOT NULL,
 CONSTRAINT `PK_ElementType_KElementType` PRIMARY KEY 
(
	`ElementTypeId` ASC
)
) 
;
/****** Object:  Table `ElementType_QElementType`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ElementType_QElementType`(
	`ElementTypeId` INT NOT NULL,
 CONSTRAINT `PK_ElementType_QElementType` PRIMARY KEY 
(
	`ElementTypeId` ASC
)
) 
;
/****** Object:  Table `EmailAttachmentsRelation`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `EmailAttachmentsRelation`(
	`EmailId` CHAR(36) NOT NULL,
	`AttachmentId` CHAR(36) NOT NULL,
 CONSTRAINT `PK_EmailAttachmentsRelation` PRIMARY KEY 
(
	`EmailId` ASC,
	`AttachmentId` ASC
)
) 
;
/****** Object:  Table `Emails`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Emails`(
	`UserId` CHAR(36) NOT NULL,
	`EmailAddress` varchar(100) NOT NULL,
	`Ordinal` int NOT NULL,
	`Verified` TINYINT(1) NULL,
	`Date` datetime  NOT NULL,
	`VerificationCode` CHAR(36) NULL,
	`HavingProblems` TINYINT(1) NULL,
 CONSTRAINT `PK_Emails` PRIMARY KEY 
(
	`UserId` ASC,
	`EmailAddress` ASC
)
) 
;
/****** Object:  Table `ErrorCategories`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorCategories`(
	`Id` int AUTO_INCREMENT NOT NULL,
	`Name` varchar(255) NOT NULL,
 CONSTRAINT `PK_ErrorCategories` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `ErrorCategories_HErrorCategory`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorCategories_HErrorCategory`(
	`Id` int NOT NULL,
 CONSTRAINT `PK_ErrorCategories_HErrorCategory` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `ErrorCategories_KErrorCategory`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorCategories_KErrorCategory`(
	`Id` int NOT NULL,
 CONSTRAINT `PK_ErrorCategories_KErrorCategory` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `ErrorCategories_QErrorCategory`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorCategories_QErrorCategory`(
	`Id` int NOT NULL,
 CONSTRAINT `PK_ErrorCategories_QErrorCategory` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `ErrorKinds`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorKinds`(
	`Id` int AUTO_INCREMENT NOT NULL,
	`Name` varchar(255) NOT NULL,
 CONSTRAINT `PK_ErrorKinds` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `ErrorKinds_HErrorKind`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorKinds_HErrorKind`(
	`Id` int NOT NULL,
 CONSTRAINT `PK_ErrorKinds_HErrorKind` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `ErrorKinds_KErrorKind`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorKinds_KErrorKind`(
	`Id` int NOT NULL,
 CONSTRAINT `PK_ErrorKinds_KErrorKind` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `ErrorKinds_QErrorKind`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorKinds_QErrorKind`(
	`Id` int NOT NULL,
 CONSTRAINT `PK_ErrorKinds_QErrorKind` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `ErrorType`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorType`(
	`ErrorTypeId` INT auto_increment  NOT NULL,
	`ErrorTypeValue` varchar(255) NOT NULL,
	`SortOrder` int NOT NULL,
	`ErrorCategoryId` int NOT NULL,
	`ErrorKindId` int NOT NULL,
 CONSTRAINT `PK_ErrorType` PRIMARY KEY 
(
	`ErrorTypeId` ASC
)
)  
;
/****** Object:  Table `ErrorType_HErrorType`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorType_HErrorType`(
	`ErrorTypeId` INT NOT NULL,
	`Penalty` float NOT NULL,
 CONSTRAINT `PK_ErrorType_HErrorType` PRIMARY KEY 
(
	`ErrorTypeId` ASC
)
) 
;
/****** Object:  Table `ErrorType_KErrorType`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorType_KErrorType`(
	`ErrorTypeId` INT NOT NULL,
 CONSTRAINT `PK_ErrorType_KErrorType` PRIMARY KEY 
(
	`ErrorTypeId` ASC
)
) 
;
/****** Object:  Table `ErrorType_QErrorType`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ErrorType_QErrorType`(
	`ErrorTypeId` INT NOT NULL,
 CONSTRAINT `PK_ErrorType_QErrorType` PRIMARY KEY 
(
	`ErrorTypeId` ASC
)
) 
;
/****** Object:  Table `Floors`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Floors`(
	`Id` INT auto_increment  NOT NULL,
	`FloorName` varchar(255) NOT NULL,
	`FloorNameAbv` varchar(50) NULL,
	`SortOrder` int NOT NULL,
 CONSTRAINT `PK_Floors` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `Floors_HFloor`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Floors_HFloor`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Floors_HFloor` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Floors_KFloor`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Floors_KFloor`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Floors_KFloor` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Floors_QFloor`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Floors_QFloor`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Floors_QFloor` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `FormErrorElement`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `FormErrorElement`(
	`ErrorElementId` INT auto_increment  NOT NULL,
	`FormId` CHAR(36) NULL,
	`ErrorTypeId` INT NULL,
	`ElementId` CHAR(36) NULL,
	`Logbook` varchar(255) NULL,
	`TechnicalAspects` varchar(255) NULL,
	`LogbookImage` CHAR(36) NULL,
	`TechnicalAspectsImage` CHAR(36) NULL,
	`Count` int NOT NULL,
 CONSTRAINT `PK_FormErrorElement` PRIMARY KEY 
(
	`ErrorElementId` ASC
)
)  
;
/****** Object:  Table `Forms`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Forms`(
	`Id` INT auto_increment  NOT NULL,
	`CounterElement` int NOT NULL,
	`Date` datetime  NULL,
	`PresentClient` varchar(255) NULL,
	`ApprovedLimits` int NOT NULL,
	`AreaCode` varchar(255) NULL,
	`Faults` int NULL,
	`Comments` varchar(255) NULL,
	`AuditId` CHAR(36) NOT NULL,
	`CategoryId` CHAR(36) NOT NULL,
	`FloorId` CHAR(36) NOT NULL,
	`AuditBy_Id` CHAR(36) NULL,
	`Uploaded` TINYINT(1) NULL,
	`Remarks` varchar(255) NULL,
	`AreaDescId` int NULL,
	`AreaDescModuleId` int NULL,
 CONSTRAINT `PK_Forms` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `HotelAreaResult`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `HotelAreaResult`(
	`AuditId` CHAR(36) NOT NULL,
	`AreaCode` varchar(100) NOT NULL,
	`AttendantName` varchar(255) NOT NULL,
	`Evaluation` float NOT NULL,
	`ApprovedLimit` float NOT NULL,
	`AreaType` int NOT NULL,
 CONSTRAINT `PK_HotelAreaResult` PRIMARY KEY 
(
	`AuditId` ASC,
	`AreaCode` ASC
)
)  
;
/****** Object:  Table `Images`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Images`(
	`ImageId` CHAR(36) NOT NULL,
	`ImageDataLocation` varchar(100) NOT NULL,
	`ImageMimeType` varchar(20) NOT NULL,
 CONSTRAINT `PK_Images` PRIMARY KEY 
(
	`ImageId` ASC
)
) 
;
/****** Object:  Table `Modules`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Modules`(
	`Id` int AUTO_INCREMENT NOT NULL,
	`Name` varchar(255) NOT NULL,
	`AreaName` varchar(255) NOT NULL,
 CONSTRAINT `PK_Modules` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `PendingEmails`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `PendingEmails`(
	`Id` INT NOT NULL,
	`UserId` CHAR(36) NOT NULL,
	`EmailAddress` varchar(100) NOT NULL,
	`MailBody` varchar(255) NULL,
	`MailHtmlBody` varchar(255) NULL,
	`MailSubject` varchar(255) NULL,
	`LastError` varchar(255) NULL,
	`LanguageCode` varchar(10) NULL,
 CONSTRAINT `PK_PendingEmails` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `PendingImages`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `PendingImages`(
	`ImageId` CHAR(36) NOT NULL,
	`Date` datetime  NOT NULL,
 CONSTRAINT `PK_PendingImages` PRIMARY KEY 
(
	`ImageId` ASC
)
) 
;
/****** Object:  Table `PerformerType`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `PerformerType`(
	`Id` int AUTO_INCREMENT NOT NULL,
	`Name` varchar(255) NOT NULL,
 CONSTRAINT `PK_PerformerType` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `RatingValue`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `RatingValue`(
	`RatingValue` float NULL,
	`Id` INT auto_increment  NOT NULL,
 CONSTRAINT `PK_RatingValue_1` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `ResultAuditCategory`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `ResultAuditCategory`(
	`IdAudit` CHAR(36) NOT NULL,
	`IdCategory` CHAR(36) NOT NULL,
	`CounterElements` int NULL,
	`ApproveLimit` int NULL,
	`Rating` float NULL,
	`IsSuficient` TINYINT(1) NULL,
 CONSTRAINT `PK_ResultAuditCategory` PRIMARY KEY 
(
	`IdAudit` ASC,
	`IdCategory` ASC
)
) 
;
/****** Object:  Table `StandardTextsReport`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `StandardTextsReport`(
	`Language` varchar(10) NOT NULL,
	`FieldName` varchar(50) NOT NULL,
	`FieldValue` varchar(255) NULL,
	`Observations` varchar(255) NULL,
	`ReportType` int NOT NULL,
 CONSTRAINT `PK_StandardTextsReport` PRIMARY KEY 
(
	`Language` ASC,
	`FieldName` ASC,
	`ReportType` ASC
)
)  
;
/****** Object:  Table `TypeOfPerformers`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `TypeOfPerformers`(
	`Performers_Id` CHAR(36) NOT NULL,
	`PerformerTypes_Id` int NOT NULL
) 
;
/****** Object:  Table `Users`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Users`(
	`Id` INT auto_increment  NOT NULL,
	`UserName` varchar(255) NOT NULL,
	`FirstName` varchar(255) NULL,
	`LastName` varchar(255) NULL,
	`ProfileImage` CHAR(36) NULL,
 CONSTRAINT `PK_Users` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `Users_Administrator`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Users_Administrator`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Users_Administrator` PRIMARY KEY 
(
	`Id` ASC
)
) 
;
/****** Object:  Table `Users_Auditor`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Users_Auditor`(
	`Phone` varchar(255) NULL,
	`Mobile` varchar(255) NULL,
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Users_Auditor` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `Users_Client`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Users_Client`(
	`CompanyName` varchar(255) NOT NULL,
	`ContactPerson` varchar(255) NULL,
	`Phone` varchar(255) NULL,
	`Mobile` varchar(255) NULL,
	`Fax` varchar(255) NULL,
	`StreetName` varchar(255) NULL,
	`ZipCode` varchar(255) NULL,
	`City` varchar(255) NULL,
	`State` varchar(255) NULL,
	`CountryId` CHAR(36) NULL,
	`Id` INT NOT NULL,
	`Branch_Id` CHAR(36) NULL,
	`URLClientPortal` varchar(100) NULL,
	`ReportType` int NOT NULL,
 CONSTRAINT `PK_Users_Client` PRIMARY KEY 
(
	`Id` ASC
)
)  
;
/****** Object:  Table `Users_Superadministrator`    Script Date: 2/16/2025 9:15:41 PM ******/

CREATE TABLE `Users_Superadministrator`(
	`Id` INT NOT NULL,
 CONSTRAINT `PK_Users_Superadministrator` PRIMARY KEY 
(
	`Id` ASC
)
) 
;