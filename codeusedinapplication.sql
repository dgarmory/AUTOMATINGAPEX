-- the report which shows the types and icons uses this
-- do not escape special characters the icons obviously
select ID,
       CODE,
       LOCATION_TYPE,
       DESCRIPTION,
       ICON_NAME,
       '<img src="https://icons.iconarchive.com/icons/icons-land/vista-map-markers/48/'||icon_name||'" alt="Icons not working">' icons
  from LOCATION_TYPES;
  
-- radio group which you use to select icons for a location is pretty identical
  select  '<img src="https://icons.iconarchive.com/icons/icons-land/vista-map-markers/48/'||icon_name||'" alt="Icons not working">' icons, icon_name  from mmt.map_icons;
  
-- and the map itself is powered by this with the icon field being what we need most :)
SELECT 
loc.lat, 
loc.lng, 
loc.name,
loc.id, 
loc.description ||mmt.get_location_html (loc.id, loc.location_type_id) AS info,
'https://icons.iconarchive.com/icons/icons-land/vista-map-markers/'||nvl(:p10_icon_size, 48)||'/'||lt.icon_name
AS icon, 
loc.name AS label
from mmt.LOCATIONS loc,
table(mmt.get_fs_location_data(:APP_PAGE_ID, 'LOC')) fs,
mmt.location_types lt
where fs.location_type_id = lt.code
and lt.id = loc.location_type_id
and fs.OVERALL_RATING = loc.OVERALL_RATING
and fs.DOG_FRIENDLINESS = loc.DOG_FRIENDLINESS
and fs.OFF_THE_BEATEN_TRACK = loc.OFF_THE_BEATEN_TRACK;

-- as a bonus for anyone who comes to my blog if you want to geocode from a trigger do this
-- you need to use your own google key
CREATE OR REPLACE EDITIONABLE TRIGGER  "LOCATIONS_TRG" 
              before insert or update on mmt.locations
              for each row
              begin
                  if :new.id is null then
                      select mmt.locations_SEQ.nextval into :new.id from sys.dual;
                 end if;
                 if (:new.address is not null and :new.address <> nvl(:old.address,'%$%#^')) then
                    begin
                    select geocode.lat, geocode.lng into :new.lat, :new.lng 
                    from json_table(apex_web_service.make_rest_request(p_url => 'https://maps.googleapis.com/maps/api/geocode/json?address='||replace(:new.address,' ','+')||',&key=yourkey'
                                                              ,p_http_method       =>  'GET'
		                                               )
                         , '$.results.geometry.location[*]'
                            columns(lat    varchar2(200)  path '$.lat'
				     ,lng    varchar2(200) path '$.lng')) geocode;
                     exception when no_data_found then
                         null;
                         -- if we can't geocode it no problem just move on
                     end;
                 end if;
              end;

