import * as fs from "node:fs";
import path from "node:path";
import FormData from "form-data";

declare global {
  const core: any;
}

const {
  MOD_NAME: mod,
  MOD_VERSION: ver,
  FACTORIO_MOD_API_KEY: apiKey,
} = process.env;

const params = new FormData();
params.append("mod", mod);

try {
  const init = await fetch(
    "https://mods.factorio.com/api/v2/mods/releases/init_upload",
    {
      method: "POST",
      body: params,
      headers: {
        Authorization: `Bearer ${apiKey}`,
      },
    }
  );

  const { upload_url } = await init.json();
  core.setSecret(upload_url);
  const dist = path.join("./dist", `${mod}_${ver}.zip`);
  const form = new FormData();
  form.append("file", fs.createReadStream(dist));

  const response = await fetch(upload_url, { method: "POST", body: form });
  await response.json();
  console.log("Upload of", dist, "succeeded!");
} catch (err) {
  console.log(err);
}
