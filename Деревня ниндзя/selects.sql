-- все жители конохи текущие
select (id, first_name, last_name)
from villager
where village_id = (select id from ninja_village where name = 'Коноха')
  and death_date is null;

-- ниндзя конохи живые
select (id, first_name, last_name)
from villager
inner join ninja on villager.id = ninja.ninja_id
where village_id = (select id from ninja_village where name = 'Коноха')
  and death_date is null;

-- текущие джинчуурики деревни Коноха
select (v.id, v.first_name, v.last_name, bidju.name)
from villager v
         inner join jinchuuriki j on j.ninja_id = v.id
         inner join bidju on j.bidju_id = bidju.id where v.death_date is null and v.village_id =  (select id from ninja_village where name = 'Коноха');

-- все члены клана Сенджу
select (id, first_name, last_name) from villager inner join ninja on villager.id = ninja.ninja_id where ninja.clan_id = (select id from clan where name='Сенджу');


