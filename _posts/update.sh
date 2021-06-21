#!/bin/sh

cp ~/vimwiki/blog/* ~/wares/blog/_posts/; cd ~/wares/blog; git add .; git cm "update"; git push
