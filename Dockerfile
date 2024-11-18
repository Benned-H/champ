FROM ros:noetic-robot AS champ-noetic
ENV ROS_DISTRO=noetic

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3-pip python3-rosdep python3-catkin-tools

RUN rm /etc/ros/rosdep/sources.list.d/20-default.list
RUN rosdep init && \
    rosdep update

# Install the list of catkin package dependencies from the host machine
# To create this file, run (on the host): python3 docker/ros_deps_scraper.py
ARG DEP_FILE="catkin_package_deps.txt"
ARG HOST_DEP_PATH="docker/${DEP_FILE}"
ARG BUILD_DEP_PATH="/tmp/${DEP_FILE}"

COPY "${HOST_DEP_PATH}" "${BUILD_DEP_PATH}"

# Verify that the dependency file exists within the build and is non-empty
RUN if [ ! -f "${BUILD_DEP_PATH}" ]; then \
    echo "Error: ${BUILD_DEP_PATH} not found!" && exit 1; \
    elif [ ! -s "${BUILD_DEP_PATH}" ]; then \
    echo "Error: ${BUILD_DEP_PATH} is empty!" && exit 1; \
    else \
    cat ${BUILD_DEP_PATH}; \
    fi;

# Resolve the package dependencies using rosdep, then install
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN RESOLVED_PACKAGES=""; \
    # Iterate over packages and attempt to resolve each
    while read -r package; do \
    echo "Package: '$package'"; \
    #
    # Capture stdout and stderr to check if rosdep resolve fails
    # TODO: Check if additional > /dev/null is necessary
    rosdep_output=$(rosdep resolve "$package" 2>&1); \
    if [ $? -ne 0 ]; then \
    echo "  $rosdep_output"; \
    else \
    resolved_package=$(echo "$rosdep_output" | tail -n1); \
    echo "  Resolved package '$package' as '$resolved_package'"; \
    RESOLVED_PACKAGES="$RESOLVED_PACKAGES $resolved_package"; \
    fi; done < "${BUILD_DEP_PATH}"; \
    #
    # Install the aggregated resolved packages
    if [ -n "$RESOLVED_PACKAGES" ]; then \
    echo "Installing packages: $RESOLVED_PACKAGES"; \
    echo "$RESOLVED_PACKAGES" | xargs apt-get install -y --no-install-recommends; \
    else \
    echo "No resolvable packages found"; \
    fi;

WORKDIR /docker/champ
