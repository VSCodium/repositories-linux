export async function onRequestGet(ctx) {
  const path = new URL(ctx.request.url).pathname.replace("/deb/pool/main/c/codium/", "")
  const file = await ctx.env.PACKAGES.get(path);

  if(!file) {
    return new Response(null, { status: 404 });
  }
  else {
    return new Response(file.body, {
      headers: { "Content-Type": file.httpMetadata.contentType },
    });
  }
}
