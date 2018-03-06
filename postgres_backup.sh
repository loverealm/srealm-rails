export PGUSER=postgres
export PGPASSWORD=30987l!Pwus3
DBNAME=loverealm_production2
now="$(date +'%d_%m_%Y_%H_%M_%S')"
EXPORTFILE=loverealm_production_$now.sql
#EXPORTFILE=loverealm_production_`date +%F`.sql
cd /var/www/backups/production/
pg_dump -O -c -f $EXPORTFILE $DBNAME
gzip $EXPORTFILE
rm -f $EXPORTFILE
