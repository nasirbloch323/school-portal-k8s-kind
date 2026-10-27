# ============================================================
# Dockerfile - website ka "container image" banane ki recipe
# ============================================================
# Image ek packed dabba hai jisme nginx + hamari website files hoti hain.
# Kubernetes isi image se Pods (running containers) banata hai.

# 1) Base image: nginx ka "unprivileged" version.
#    - "unprivileged" ka matlab: root user ki jagah normal user se chalta hai
#      (security best practice, real companies yehi use karti hain).
#    - Ye port 8080 par sunta hai (80 par nahi, kyunke 1024 se kam port ke liye root chahiye).
#    - Version pin kiya hai (1.27-alpine). "latest" kabhi use nahi karte
#      kyunke kal ko version badal sakta hai aur app toot sakti hai.
FROM nginxinc/nginx-unprivileged:1.27-alpine

# 2) Hamari website files (html, css) image ke andar copy karo.
#    /usr/share/nginx/html wo folder hai jahan se nginx website serve karta hai.
COPY app/index.html /usr/share/nginx/html/index.html
COPY app/style.css  /usr/share/nginx/html/style.css

# 3) Documentation ke liye: container port 8080 par chalta hai.
EXPOSE 8080

# Note: CMD likhne ki zaroorat nahi, base image mein pehle se nginx start
# karne ka command maujood hai.
