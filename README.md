#### Telephone scheduler

An example of how to use terraform, twilio, and documentdb (amazon's proprietary version of mongo).

This repo contains python code to populate a documentdb database, and to send messages to recipients on a schedule, both contained in that database. It also contains terraform files to deploy these to aws.

It also contains a github workflow to repeatedly apply the content of the `infrastructure` directory
