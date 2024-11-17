FROM ros:noetic-robot AS champ-noetic
ENV ROS_DISTRO=noetic

# Run commands from CHAMP's original README
RUN apt-get install -y python-rosdep

ENTRYPOINT ["bash", "docker/entrypoint.sh"]
WORKDIR /docker/champ
