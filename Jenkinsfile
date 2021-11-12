def props = [
    imageName: 'spawner',
    registry: 'registry.cloud.mov.ai',
    registryCredential : 'jenkins-registry-creds',
    buildFolder: '.'
]

def imageEnv = ''
def imagePpaArg = ''
def buildId = "${env.BRANCH_NAME}-${BUILD_NUMBER}".replace('/', '-')

pipeline {
    agent any
    stages {
        stage('Build Test Deploy') {
            matrix {
                axes {
                    axis {
                        name 'ROS_VERSION'
                        values 'noetic', 'melodic'
                    }
                }
                stages {
                    stage('Prepare') {
                        steps {
                            echo "Do Prepare for ${ROS_VERSION}"
                            script {
                                imageEnv = 'develop'
                                imagePpaArg = 'dev'
                                if (env.BRANCH_NAME.matches('prod|release-.+|v.+')) {
                                    imageEnv = 'release'
                                    imagePpaArg = 'main'
                                    dockerTarget = 'builder-release'
                                } else if ( env.BRANCH_NAME == 'qa' ) {
                                    imageEnv = 'qa'
                                    imagePpaArg = 'testing'
                                    dockerTarget = 'builder-qa'
                                } else if ( env.BRANCH_NAME.matches( 'develop|PR-.+' )) {
                                    imageEnv = 'develop'
                                    imagePpaArg = 'dev'
                                    dockerTarget = 'builder-develop'
                                } else if ( env.BRANCH_NAME == 'main' ) { // 2.2
                                    imageEnv = 'qa'
                                    imagePpaArg = 'testing'
                                    dockerTarget = 'builder-qa'
                                }
                            }
                        }
                    }
                    stage('Build') {
                        steps {
                            echo "Do Build for ${ROS_VERSION}"
                            script {
                                ansiColor('xterm') {
                                    def buildImgName = "${imageEnv}/${props.imageName}-${ROS_VERSION}:${buildId}"
                                    def buildFile = "./docker/${ROS_VERSION}/Dockerfile"

                                    withCredentials([file(credentialsId: 'private-sshkey-automation', variable: 'sshkeyfile')]) {
                                        dir("${props.buildFolder}/ssh-keys") {
                                            sh 'cp -vf ${sshkeyfile} .'
                                        }
                                        dir (props.buildFolder) {
                                            docker.withRegistry( "https://${props.registry}", props.registryCredential ) {
                                                def buildArgs = '--pull --no-cache --rm' +
                                                " --target ${dockerTarget}" +
                                                " --file \"${buildFile}\" ."

                                                dockerImage = docker.build(buildImgName, buildArgs)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    stage('Test') {
                        steps {
                            echo "Do Test for ${ROS_VERSION}"
                            script {
                                def buildImgName = "${imageEnv}/${props.imageName}-${ROS_VERSION}:${buildId}"
                                docker.image(buildImgName).inside('') { testContainer ->
                                    // Test image match expectation

                                    def output = sh(returnStdout: true, script: 'rosversion -d').trim()
                                    if ( output == "${ROS_VERSION}") {
                                        echo 'Good ROS version'
                                    } else {
                                        error "Bad ROS version: ${ROS_VERSION}"
                                    }

                                    def python_version = sh(returnStdout: true, script: 'python --version 2>&1').trim()
                                    if ( python_version.startsWith('Python 2.') && "${ROS_VERSION}" == 'melodic') {
                                        echo 'Good Python version for melodic'
                                    } else if ( python_version.startsWith('Python 3.') && "${ROS_VERSION}" == 'noetic') {
                                        echo 'Good Python version for noetic'
                                    } else {
                                        error "Bad ${python_version} version for: ${ROS_VERSION}"
                                    }
                                }
                            }
                        }
                    }
                    stage('Deploy') {
                        steps {
                            echo "Do Deploy for ${ROS_VERSION}"
                            script {
                                branchName = "${env.BRANCH_NAME}"

                                if (branchName.matches('develop|qa|prod|release-.+|v.+|main|PR-.+')) {
                                    docker.withRegistry( "https://${props.registry}", props.registryCredential ) {
                                        def buildImgName = "${imageEnv}/${props.imageName}-${ROS_VERSION}:${buildId}"
                                        def dockerImage = docker.image(buildImgName)
                                        def imageVersion = "${env.BRANCH_NAME}"

                                        // example: develop/spawner-melodic:main-21
                                        //println ("Pushing ${buildId}")
                                        //dockerImage.push(buildId)

                                        println ("Pushing ${imageVersion}")
                                        dockerImage.push(imageVersion)
                                    }
                                }
                            }
                        }
                    }
                    stage('Clean') {
                        steps {
                            echo "Do Clean for ${ROS_VERSION}"
                            script {
                                def buildImgName = "${imageEnv}/${props.imageName}-${ROS_VERSION}:${buildId}"
                                echo "Do Clean for ${ROS_VERSION}"
                                sh "docker rmi ${buildImgName}"
                            }
                        }
                    }
                }
            }
        }
    }
}
