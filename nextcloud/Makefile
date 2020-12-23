
images = nextcloud_app 
containers = nextcloud_app_1 nextcloud_db_1
data_dir = /media/pleiades/nextcloud/*

all:
	docker-compose up -d

clean:
	docker stop $(containers)
	docker rm $(containers)
	docker volume prune
	sudo rm -rf $(data_dir)

imgclean: 
	docker rmi $(images)

.PHONY: all clean
