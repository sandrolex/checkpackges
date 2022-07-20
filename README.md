# Container checkpackages

Tool for validating packages installed in a docker image

Supports Ubuntu, Debian, Centos and Alpine

## Build 
```bash
make build 
```

## Install
```bash
make install
```

with docker 
```bash
docker build -t checkpackages . 
```


## Usage
checkpackages check installed packages in the docker images and compares it to the policy file

returns 1 if unauthorized packages found, 0 otherwise


```bash
checkpackages [IMAGE] [POLICY-FILE]
```

with docker
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v [POLICY_PATH]:/tmp/policy checkpackages [IMAGE] /tmp/policy
```


## Policy file
One package per line

to exlude a patern, use prefix !


Example:
```bash
apache2
!libapache2-mod-apparmor
```

will fail on apache2, but not on libapache2-mod-apparmor

## Test
```
docker build -t checkpackages . 
cd test
sh test_all.sh
```

# Bundle container security checks

Runs checkpackages + dockle + snyk agaisnt an image


## Build docker image
```
cd scripts
sh build.sh
```

## Run bundle container
```
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -e SNYK_TOKEN=[TOKEN] secbundle [image:tag]

docker run --rm -e MONITOR=true -e NONBLOCKING=true PROFILE=base-images -v /var/run/docker.sock:/var/run/docker.sock -e SNYK_TOKEN=[TOKEN] secbundle [image:tag]
```

## ENV VARS
<table>
<tr><th>VAR</th><th>description</th><th>values</th><th>default</th></tr>
<tr><td>MONITOR</td><td>Execute Snyk monitor</td><td>true|false</td><td>false</td></tr>
<tr><td>NONBLOCKING</td><td>Always set exit code to 0</td><td>true|false</td><td>false</td></tr>
<tr><td>PROFILE</td><td>Sets the container policy profile</td><td>prod|base-image</td><td>prod</td></tr>
</table>
