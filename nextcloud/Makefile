
images = nextcloud_app
containers = nextcloud_app_1 nextcloud_db_1
data_dir = /media/pleiades/nextcloud/*

# Run nextcloud app using settings in docker-compose.
all:
	docker-compose up -d

# Stop & remove nextcloud app, remove volumes and clean data directory
clean:
	-docker stop $(containers)
	-docker rm $(containers)
	-docker volume prune
	-sudo rm -rf $(data_dir)

# Performs clean and also removes any preexisting nextcloud image.
imgclean: clean
	-docker rmi $(images)

.PHONY: all clean
