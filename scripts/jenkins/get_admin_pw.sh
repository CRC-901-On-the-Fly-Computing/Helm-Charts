kubectl get secret jenkins -n jenkins -o yaml | grep "admin-password" | awk '{print $2}' |base64 --decode | awk 1
