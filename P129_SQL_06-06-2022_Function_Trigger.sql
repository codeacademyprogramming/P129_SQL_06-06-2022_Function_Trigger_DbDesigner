Create Database P129FunctionTrigger

Use P129FunctionTrigger

CREATE TABLE Authors
(
	Id INT CONSTRAINT PK_Authors_Id PRIMARY KEY Identity,
	Name nvarchar(255) CONSTRAINT CK_Authors_Name CHECK(LEN(Name) > 1),
	SurName nvarchar(255) CONSTRAINT CK_Authors_SurName CHECK(LEN(SurName) > 1)
)

CREATE TABLE Books
(
	Id INT CONSTRAINT PK_Books_Id PRIMARY KEY Identity,
	Name nvarchar(100) CONSTRAINT CK_Books_Name CHECK(LEN(Name) BETWEEN 2 AND 100),
	PageCount INT CONSTRAINT CK_Books_PageCount CHECK(PageCount >= 10),
	AuthorId INT CONSTRAINT FK_Books_AuthorId FOREIGN KEY REFERENCES Authors(Id)
)

INSERT INTO Authors 
VALUES
('Stephen', 'King'),
('J.K.', 'Rowling'),
('Amy', 'Tan'),
('Khaled', 'Hosseini'),
('Tana', 'French')

INSERT INTO Books 
VALUES
('It', 543, 1),
('The Shining', 524, 1),
('Misery', 629, 1),
('Carrie', 785, 1),
('Harry Potter', 683, 2),
('Harry Potter 2', 755, 2),
('Harry Potter 3', 531, 2),
('Harry Potter 4', 624, 2),
('Harry Potter 5', 764, 2),
('The Joy Luck Club', 311, 3),
('The Kitchen Gods Wife', 855, 3),
('The Hundred Secret Senses', 345, 3),
('The Bonesetters Daughter', 286, 3),
('The Valley of Amazement', 717, 3),
('THE KITE RUNNER', 863, 4),
('And the Mountains Echoed', 433, 4),
('A Thousand Splendid Suns', 866, 4),
('Sea Prayer', 865, 4),
('The Kite Runner', 326, 4),
('The Searcher', 289, 5),
('The Likeness', 429, 5),
('Faithful Place', 678, 5),
('The Secret Place', 435, 5)


--1. Function
--1.1 Create Function
Create Function usf_GetBooksCountByAuthorNameAndPageCount
(@pagecount int, @authorName nvarchar(255))
returns int
As
Begin
	declare @booksCount int

	Select @booksCount = COUNT(*) From Books
	Join Authors On Books.AuthorId = Authors.Id
	Where Authors.Name = @authorName And Books.PageCount > @pagecount

	return @booksCount
End

--1.2 Update Function
Alter Function usf_GetBooksCountByAuthorNameAndPageCount
(@pagecount int, @authorName nvarchar(255))
returns int
As
Begin
	declare @booksCount int

	Select @booksCount = COUNT(*) From Books
	Join Authors On Books.AuthorId = Authors.Id
	Where Authors.Name Like'%'+@authorName+'%' And Books.PageCount > @pagecount

	return @booksCount
End

Select dbo.usf_GetBooksCountByAuthorNameAndPageCount(600,N'n') 'Books Count'


Create Table BooksArchive
(
	Id INT,
	Name nvarchar(100),
	PageCount INT,
	AuthorId INT
)

Alter Table BooksArchive
Add StatementType nvarchar(255)

Alter Table BooksArchive
Add Date Datetime2

--2. Trigger
--2.1 Create Trigger
Create Trigger BooksInsertTrigger
On Books
after insert
As
Begin
	declare @id int
	declare @name nvarchar(100)
	declare @pageCount int
	declare @authorId int

	Select @id = book.Id from inserted book
	Select @name = book.Name from inserted book
	Select @pageCount = book.PageCount from inserted book
	Select @authorId = book.AuthorId from inserted book

	Insert Into BooksArchive(Id, Name, PageCount, AuthorId,)
	Values
	(@id, @name, @pageCount, @authorId)
End

--2.2 Update Trigger
Alter Trigger BooksInsertTrigger
On Books
after insert,delete
As
Begin
	declare @id int
	declare @name nvarchar(100)
	declare @pageCount int
	declare @authorId int
	declare @stateType nvarchar(255)

	Select @id = book.Id from inserted book
	Select @name = book.Name from inserted book
	Select @pageCount = book.PageCount from inserted book
	Select @authorId = book.AuthorId from inserted book
	Select @stateType = 'Created Object' from inserted book

	Select @id = book.Id from deleted book
	Select @name = book.Name from deleted book
	Select @pageCount = book.PageCount from deleted book
	Select @authorId = book.AuthorId from deleted book
	Select @stateType = 'Deleted Object' from deleted book

	Insert Into BooksArchive(Id, Name, PageCount, AuthorId,StatementType,Date)
	Values
	(@id, @name, @pageCount, @authorId,@stateType,GETDATE())
End


Create Trigger BooksUpdateTrigger
on Books
After Update
As
Begin
	declare @id int
	declare @name nvarchar(100)
	declare @pageCount int
	declare @authorId int
	declare @stateType nvarchar(255)

	Select @id = book.Id from inserted book
	Select @name = book.Name from inserted book
	Select @pageCount = book.PageCount from inserted book
	Select @authorId = book.AuthorId from inserted book
	Select @stateType = 'Updated Object' from inserted book

	Insert Into BooksArchive(Id, Name, PageCount, AuthorId,StatementType,Date)
	Values
	(@id, @name, @pageCount, @authorId,@stateType,GETDATE())
End

Insert Into Books(Name, PageCount, AuthorId)
Values
('Test-4',170,2)

Delete Books Where Id = 33

Update Books Set Name = 'Test 4' Where Id = 33

exec sp_rename 'BooksInsertTrigger', 'BooksInsertAndDeleteTrigger'

exec sp_rename 'BooksArchive','BooksBackup'

exec sp_rename 'BooksBackup','BooksArchive'

exec sp_rename 'BooksBackup.Date','ModifiedDated'

exec sp_rename 'BooksArchive.ModifiedDated','Date'


--3. Index
Select * From Books

Create Index BookNameIndex
on Books(Name)

Drop Index BookNameIndex On Books