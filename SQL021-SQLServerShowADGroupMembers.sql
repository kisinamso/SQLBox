DECLARE @GroupName VARCHAR(100) = 'DOMAINNAME\GroupName'
EXEC master..xp_logininfo @acctname = @GroupName ,@option = 'members' -- show group members
