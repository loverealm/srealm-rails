# README #

### Organize Git ###
* **master**  - branch for production, only tested features from staging merge to master.
* **staging** - branch for staging (test) version. Pre-production version of application.
* **dev** - branch for development, local branches ( specific features) merge to dev.
* **local_branch** - branches for development particular features (*name as last part of trello url for that feature*); these branches need to be at your machine until it is ready to production.

### Necessary things ###
* Rails 4.1.8
* Ruby 2.1.5
* PostgreSql 9.3
* Additional packages: libsnappy-dev

### How do I get set up? ###
  * Clone dev branch.
  * Get into project via console and run bundle install.
  * Run rake db:create db:migrate db:seed
  * Create your local branch - git checkout -b branch_name from dev
  *  After you finish particular feature, commit and push your local branch (! add meaningful commit message for better       understanding)

### Development process ###
* FrontEnd team and BackEnd team.
* After particular feature from *FE/BE* is finished, move it to *Review* and assign another guy from your team, with appropriate comment and branch name. Also, very important thing is to create **PULL REQUEST** on bitbucket and to assign the same guy as on Trello.
* When this feature is reviewed by colleague, he needs to move it to *For Testing*, merge to **dev** branch and set flag color **YELLOW**. All yellow ticket need to be deployed to Staging Version(BE team) and then assigned to Product Owner. BE team, need to merge all *yellow* features from *For Testing* to **staging** branch and deploy to Staging Version.
*  Product Owner can test only yellow tickets from *For Testing* which are assigned to him, and after everything is ok, move it to *Approved and Tested By Product Owner*; if something missing or wrong, move ticket to *Bugs* and change flag colour to **RED** with appropriate comment related to bug. Project Lead, in meantime, assigns tickets from *Bugs* to ticket owner.
* Tickets in *Bugs* have priority.
* All tickets in *Approved and Tested By Product Owner* are ready for production. Local branches for approved features have to be merged into master and then do deploy to production. After they deployed on live, local branch and remote branch for that particular feature can be removed.

### List of scheduled jobs ###
* [daily] rake sitemap:refresh

## Api Docs
Here you can see the docs and test your API's
* Swagger:
  http://loverealm.com:8080/swagger/dist/index.html?url=/api/v1/documentations/pub   
  Please see here how to add docs and regenerate: https://github.com/richhollis/swagger-docs   
  Note: After update/regenerated don't forget to commit the changes to have updated the docs for mobile team 

* Static mobile Docs (Previous Developers docs)
  http://loverealm.com:8080/swagger/dist/index.html?url=/api/v1/documentations
  

## Define environments vars
* AWS_HOST=   
* AWS_REGION=   
* S3_BUCKET=   
* AWS_KEY=   
* AWS_SECRET=   
* PUB_NUB_PUBLISHKEY=pub-c-fc16b669-d062-4b78-841b-46b0f0f04844   
* PUB_NUB_SUBSKEY=sub-c-ae77bcee-d395-11e6-b691-02ee2ddab7fe   
* PUB_NUB_SECRET=sec-c-ZDUyYWM3YmYtNDY3YS00OTRjLWE5NTUtMzBhN2JjYTI0MmJi
* FCM_PUBLIC_TOPIC=4y3cVGX

## Production Deploy
* Backup DB
* Set ENV vars
* Set/Update cronjobs
* Deploy master branch
* Install FFMPEG
* Create aws account (to save media files)
* Create fcm account (instant messaging for mobile)
* Create pubnup account (instant messaging)
* Create opentok account (video chat and live streaming)
* Setup Callback URL on opentok admin panel: https://loverealm.com/opentok/callback/<OPENTOK_CALLBACK_TOKEN>
* Create a bucket on aws to save live videos and configure it on opentok admin panel
* Dont forget to start/restart delayed job (background process)
* Install elastic search:
* Get txtlocal apikey service to calculate sms costs: https://control.txtlocal.co.uk/settings/apikeys/

## Staging notes
* Don't send emails to clients
* Don't send sms messages
* Email test account: loverealm.staging@gmail.com | ICDATtcwsmP4
* If you want to receive sms testing messages, pls send to Owen your phone number

## Extra notes
* to change currency: # need to change app_currency setting in config/initializers/custom_settings.rb and currency format in locales/en_basic.yml 