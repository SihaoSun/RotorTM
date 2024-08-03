FROM ros:noetic

ENV USERNAME RotorTM
ENV HOME /home/$USERNAME

# nvidia-container-runtime. Adds support to Nvidia drivers inside the container.
# for this to work, you need to install nvidia-docker2 in your host machine.
# More info: http://wiki.ros.org/docker/Tutorials/Hardware%20Acceleration
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

RUN useradd -m $USERNAME && \
        echo "$USERNAME:$USERNAME" | chpasswd && \
        usermod --shell /bin/bash $USERNAME && \
        usermod -aG sudo $USERNAME && \
        mkdir -p /etc/sudoers.d && \
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
        chmod 0440 /etc/sudoers.d/$USERNAME && \
        # Replace 1000 with your user/group id
        usermod  --uid 1000 $USERNAME && \
  groupmod --gid 1000 $USERNAME

USER RotorTM
WORKDIR /home/${USERNAME}

RUN sudo apt-get update

  # GCC-9
RUN sudo apt-get install -y software-properties-common
RUN sudo add-apt-repository ppa:ubuntu-toolchain-r/test
RUN sudo apt-get update
RUN sudo apt-get install -y gcc-9 g++-9

  # Set gcc-9 default GCC compiler
RUN sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-9

  # Install CLANG
RUN sudo apt-get install -y clang-10

  # Set CLANG the default compiler
ENV CC /usr/bin/clang-10
ENV CXX /usr/bin/clang++-10

  # Python and git:
RUN sudo apt-get install -y git
RUN sudo apt-get install -y python3-rosdep python3-rosinstall-generator python3-vcstool build-essential
RUN sudo apt-get install -y python3 python3-pip python3-dev

  # Dependencies for scipy
RUN sudo apt-get update && sudo apt-get install -y libblas-dev liblapack-dev gfortran

  # Python packages
RUN sudo -H pip install catkin-tools scipy

  # Libraries
RUN sudo apt-get install -y libyaml-cpp-dev libeigen3-dev libgoogle-glog-dev ccache tmux  net-tools iputils-ping nano wget usbutils htop gdb psmisc screen


  # ROS dependencies:
RUN sudo apt-get install -y \
  ros-${ROS_DISTRO}-octomap-msgs \
  ros-${ROS_DISTRO}-octomap-ros \
  ros-${ROS_DISTRO}-gazebo-plugins \
  ros-${ROS_DISTRO}-xacro \
  ros-${ROS_DISTRO}-rqt \
  ros-${ROS_DISTRO}-rviz \
  ros-${ROS_DISTRO}-plotjuggler-ros


  # Install gazebo:
RUN sudo apt-get install -y gazebo11 libgazebo11-dev


  # Create a catkin workspace
RUN /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash"
RUN mkdir -p catkin_ws/src
RUN cd catkin_ws && catkin config --init --mkdirs --extend /opt/ros/$ROS_DISTRO --merge-devel --cmake-args -DCMAKE_BUILD_TYPE=Release

  # Clone catkin_simple
RUN cd catkin_ws/src && git clone https://github.com/catkin/catkin_simple.git

#   # Clone rotors_simulators
# RUN cd catkin_ws/src && git clone https://github.com/tud-amr/rotors_simulator.git

#   # Clone mav_comm from ASL
# RUN cd catkin_ws/src && git clone https://github.com/ethz-asl/mav_comm.git

# Clone eigen_catkin
RUN cd catkin_ws/src && git clone https://github.com/ethz-asl/eigen_catkin.git

  # Do catkin build of the packages that are already there
RUN cd catkin_ws && catkin build

  # Give permissions to use tty to user
RUN sudo usermod -a -G tty $USERNAME
RUN sudo usermod -a -G dialout $USERNAME

  # Set some useful alias
RUN sudo echo 'alias sourceros="source ~/catkin_ws/devel/setup.bash && source ~/catkin_ws/src/host_dir/setupros.bash"' >> ~/.bashrc

CMD "sudo /etc/init.d/dbus start"

RUN pip install numpy==1.22.1
RUN pip install cvxopt==1.2.7
RUN pip install numpy==1.22.1
RUN pip install matplotlib