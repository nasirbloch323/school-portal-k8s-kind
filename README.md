# Green Valley School Portal - nginx on Kubernetes (kind)

Ye ek chota lekin real-life jaisa DevOps project hai. Ek school ki website
nginx par chalti hai, Docker image mein pack hoti hai, aur Kubernetes (kind)
par deploy hoti hai.

## Is project se kya seekhenge

| Topic | Kahan dekhein |
|---|---|
| Static website | `app/` |
| Docker image banana | `Dockerfile` |
| Local Kubernetes cluster (kind) | `k8s/00-kind-cluster.yaml` |
| Namespace | `k8s/01-namespace.yaml` |
| ConfigMap (nginx config) | `k8s/02-configmap.yaml` |
| Deployment, probes, resources, security | `k8s/03-deployment.yaml` |
| Service (NodePort) | `k8s/04-service.yaml` |
| Automation script | `deploy.sh`, `cleanup.sh` |

Har YAML file ke andar line by line comments hain. Pehle unhe parhein.

## Folder structure

```
school-portal/
├── app/
│   ├── index.html          # website ka page
│   └── style.css           # website ki design
├── k8s/
│   ├── 00-kind-cluster.yaml  # cluster ka naqsha
│   ├── 01-namespace.yaml     # alag classroom
│   ├── 02-configmap.yaml     # nginx ki settings
│   ├── 03-deployment.yaml    # Pods chalane wala manager
│   └── 04-service.yaml       # stable address / traffic baantna
├── Dockerfile              # image banane ki recipe
├── deploy.sh               # sab kuch deploy
├── cleanup.sh              # sab kuch delete
└── README.md
```

## Pehle ye install hona chahiye

- Docker
- kind
- kubectl

Check karein:

```bash
docker --version
kind --version
kubectl version --client
```

## Deploy kaise karein

### Aasan tareeqa (ek command)

```bash
chmod +x deploy.sh cleanup.sh
./deploy.sh
```

Phir browser mein kholein: **http://localhost:8080**

### Manual tareeqa (step by step, seekhne ke liye behtareen)

```bash
# 1. Image banao
docker build -t school-portal:1.0 .

# 2. Cluster banao
kind create cluster --name school --config k8s/00-kind-cluster.yaml

# 3. Image ko cluster mein bhejo
kind load docker-image school-portal:1.0 --name school

# 4. YAML files apply karo
kubectl apply -f k8s/01-namespace.yaml
kubectl apply -f k8s/02-configmap.yaml
kubectl apply -f k8s/03-deployment.yaml
kubectl apply -f k8s/04-service.yaml

# 5. Dekhein sab theek chal raha hai
kubectl get all -n school-portal
```

## Zaroori commands (daily DevOps kaam)

```bash
# Sab kuch dekhna
kubectl get all -n school-portal

# Pods ki list (kaun se node par chal rahe hain)
kubectl get pods -n school-portal -o wide

# Pod ke logs
kubectl logs -n school-portal -l app=school-portal

# Pod ke baare mein detail / masla dhoondna
kubectl describe pod -n school-portal -l app=school-portal

# Pod ke andar jana (nginx-unprivileged mein sh available hai)
kubectl exec -it -n school-portal deploy/school-portal -- sh
```

## Experiments (inhe zaroor try karein)

### 1. Self-healing dekhein
Ek Pod delete karein, Kubernetes khud naya bana dega:

```bash
kubectl get pods -n school-portal
kubectl delete pod <koi-ek-pod-ka-naam> -n school-portal
kubectl get pods -n school-portal -w     # -w = live dekhte rahein
```
Website beech mein bhi chalti rahegi kyunke doosra Pod maujood hai.

### 2. Scale karein
```bash
kubectl scale deployment school-portal --replicas=4 -n school-portal
kubectl get pods -n school-portal
```

### 3. Naya version deploy karein (rolling update)
1. `app/index.html` mein koi notice badlein.
2. Naya version banayein:
   ```bash
   docker build -t school-portal:1.1 .
   kind load docker-image school-portal:1.1 --name school
   kubectl set image deployment/school-portal nginx=school-portal:1.1 -n school-portal
   kubectl rollout status deployment/school-portal -n school-portal
   ```
3. Masla ho to wapas jayein (rollback):
   ```bash
   kubectl rollout undo deployment/school-portal -n school-portal
   ```

### 4. Nginx ki config badlein (ConfigMap)
`k8s/02-configmap.yaml` mein kuch badlein, phir:
```bash
kubectl apply -f k8s/02-configmap.yaml
kubectl rollout restart deployment/school-portal -n school-portal
```
Image dobara build karne ki zaroorat nahi.

## Common masle aur hal

| Masla | Wajah | Hal |
|---|---|---|
| `ErrImagePull` / `ImagePullBackOff` | Image kind ke andar load nahi hui | `kind load docker-image school-portal:1.0 --name school` |
| Pod `CrashLoopBackOff` | nginx config mein ghalti | `kubectl logs <pod> -n school-portal` |
| `localhost:8080` nahi khulta | Port 8080 laptop par kisi aur ne le rakha hai | `00-kind-cluster.yaml` mein `hostPort` badlein, cluster dobara banayein |
| Pod `Pending` | Resources kam hain | `kubectl describe pod <pod> -n school-portal` |

## Safai

```bash
./cleanup.sh
```

## Real life se rabta

- **Image mein version tag (`1.0`)**: `latest` use nahi karte, taake pata rahe kaun sa version chal raha hai.
- **ConfigMap**: config ko code se alag rakhte hain.
- **2 replicas + RollingUpdate**: update ke waqt downtime nahi.
- **Probes**: Kubernetes khud pehchanta hai app kharab hai ya nahi.
- **Resources requests/limits**: ek app poore server ko nahi kha sakti.
- **Non-root + read-only filesystem**: security best practice.
- **Namespace**: har app ka alag hissa.

## Agla qadam (jab ye samajh aa jaye)

1. Image ko Docker Hub / GitHub Container Registry par push karein.
2. NodePort ki jagah **Ingress** (nginx-ingress) lagayein aur `school.local` jaisa domain use karein.
3. **GitHub Actions** se CI/CD banayein (code push -> image build -> deploy).
4. **HPA** (autoscaling) aur **Prometheus + Grafana** (monitoring) lagayein.
5. **Helm** ya **Kustomize** seekhein taake dev/prod alag config ho.
