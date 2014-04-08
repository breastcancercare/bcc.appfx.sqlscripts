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

declare @TABLE table (ADHOCQUERYID uniqueidentifier, IDSETID uniqueidentifier)


while @@FETCH_STATUS = 0
begin
	with xmlnamespaces ('Blackbaud.AppFx.WebService.API.1' as [ns])

	insert into @TABLE
	select @AVARIABLE.value('(ns:AdHocQuery/@ID)[1]','uniqueidentifier'), T.c.value('(ns:ID)[1]', 'uniqueidentifier')
		from @AVARIABLE.nodes('ns:AdHocQuery/*/ns:f/ns:IDSetFieldInfo') as T(c)

	fetch next from ACURSOR into @AVARIABLE;	
end

close ACURSOR;
deallocate ACURSOR;

select ISR.NAME SELECTION, ISR.DESCRIPTION SELECTION_DESCRIPTION, ISR.DBOBJECTNAME SELECTION_OBJECTNAME, AQ.NAME+' (Ad-hoc Query)' USED_IN
from IDSETREGISTER ISR
	inner join @TABLE T on T.IDSETID=ISR.ID
	inner join ADHOCQUERY AQ on AQ.ID=T.ADHOCQUERYID	
	left join IDSETREGISTERADHOCQUERY ISRAQ on ISRAQ.IDSETREGISTERID=ISR.ID 
where AQ.ID is not NULL 

UNION

select ISR.NAME SELECTION, ISR.DESCRIPTION SELECTION_DESCRIPTION, ISR.DBOBJECTNAME SELECTION_OBJECTNAME, CP.NAME+' (Correspondence Process)' USED_IN
from IDSETREGISTER ISR
	inner join CORRESPONDENCEPROCESS CP on CP.IDSETREGISTERID=ISR.ID
	left join IDSETREGISTERADHOCQUERY ISRAQ on ISRAQ.IDSETREGISTERID=ISR.ID 
where CP.ID is not NULL 

UNION

select ISR.NAME SELECTION, ISR.DESCRIPTION SELECTION_DESCRIPTION, ISR.DBOBJECTNAME SELECTION_OBJECTNAME, MS.NAME +' (Marketing Segment)' USED_IN
from IDSETREGISTER ISR
	inner join MKTSEGMENTSELECTION MSS on ISR.ID=MSS.SELECTIONID
	inner join MKTSEGMENT MS on MS.ID=MSS.SEGMENTID
	left join IDSETREGISTERADHOCQUERY ISRAQ on ISRAQ.IDSETREGISTERID=ISR.ID 
where MS.ID is not NULL 
 
order by ISR.NAME
