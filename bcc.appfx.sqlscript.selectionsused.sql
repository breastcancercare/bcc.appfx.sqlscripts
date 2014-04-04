/*
Breast Cancer Care (c) 2012 - MIT Licence

Description: Lists the occurances of a selection and where it is used

Note: Ideally should be exposed on the Selections tab of Query, however that datalist
is a CLR (and also this does not list imported selections). Could be written as a 
custom action (eg right-click on query/selection, 'View uses')

*/



declare @AVARIABLE xml;
declare ACURSOR cursor local fast_forward for 
	SELECT QUERYDEFINITIONXML FROM ADHOCQUERY
	
open ACURSOR;
fetch next from ACURSOR into @AVARIABLE;

declare @TABLE table (ADHOCQUERYID uniqueidentifier, ADHOCQUERYNAME nvarchar(100), IDSETID uniqueidentifier, IDSETNAME nvarchar(100))


while @@FETCH_STATUS = 0
begin
	with xmlnamespaces ('Blackbaud.AppFx.WebService.API.1' as [ns])
	
	insert into @TABLE
	select @AVARIABLE.value('(ns:AdHocQuery/@ID)[1]','uniqueidentifier'), @AVARIABLE.value('(ns:AdHocQuery/@Name)[1]','nvarchar(100)'), ISR.ID, ISR.NAME
		from @AVARIABLE.nodes('ns:AdHocQuery/*/ns:f/ns:IDSetFieldInfo') as T(c) 
			inner join IDSETREGISTER ISR on ISR.ID=T.c.value('(ns:ID)[1]', 'uniqueidentifier')
					
	fetch next from ACURSOR into @AVARIABLE;	
end

close ACURSOR;
deallocate ACURSOR;

select ISR.NAME SELECTION, ISR.DESCRIPTION SELECTION_DESCRIPTION, ISR.DBOBJECTNAME, case when ISRAQ.ADHOCQUERYID IS null then 0 else 1 end as SELECTION_IS_QUERY , T.ADHOCQUERYNAME USED_IN_QUERY, CP.NAME USED_IN_CORRESPONDENCEPROCESS, MS.NAME USED_IN_SEGMENT
from IDSETREGISTER ISR
	left join @TABLE T on T.IDSETID=ISR.ID
	left join IDSETREGISTERADHOCQUERY ISRAQ on ISRAQ.IDSETREGISTERID=ISR.ID
	left join ADHOCQUERY AQ on AQ.ID=ISRAQ.ADHOCQUERYID	
	left join CORRESPONDENCEPROCESS CP on CP.IDSETREGISTERID=ISR.ID
	left join MKTSEGMENTSELECTION MSS on ISR.ID=MSS.SELECTIONID
	left join MKTSEGMENT MS on MS.ID=MSS.SEGMENTID
	

where not(T.ADHOCQUERYID is null and CP.ID is null and MS.ID is null) 
order by IDSETNAME
