FROM node:20-bullseye-slim

WORKDIR /app

# copy only package manifests first to leverage Docker layer caching
COPY package*.json ./

# install dependencies and ensure esbuild native binary matches container architecture
RUN npm ci --silent \
  && if [ -d node_modules/esbuild ]; then npm rebuild esbuild --update-binary && if [ -f node_modules/esbuild/bin/esbuild ]; then chmod +x node_modules/esbuild/bin/esbuild; fi; fi

# Ensure esbuild files are readable/executable (defensive, in case permissions are incorrect)
RUN chmod -R a+rx node_modules/esbuild || true

# copy rest of project
COPY . .

ENV PORT=3000
EXPOSE 3000

CMD ["npm", "run", "dev"]

