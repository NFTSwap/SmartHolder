let contractURIJSON = {
	"name": "NFTsTest",
	"description": "NFTsTest NFTsTest NFTsTest",
	"image": "https://fanyi-cdn.cdn.bcebos.com/static/translation/img/header/logo_e835568.png",
	"external_link": "external-link-url",
	"seller_fee_basis_points": 1000,
	"fee_recipient": "0x99Cd330213791CDBea135ec2E16a9d1927cb17ae"
}
let contractURIBase64 = 'data:application/json;base64,' + Buffer.from(JSON.stringify(contractURIJSON)).toString('base64');
let contractURIBase64Str = 'data:application/json;base64,eyJuYW1lIjoiTkZUc1Rlc3QiLCJkZXNjcmlwdGlvbiI6Ik5GVHNUZXN0IE5GVHNUZXN0IE5GVHNUZXN0IiwiaW1hZ2UiOiJodHRwczovL2ZhbnlpLWNkbi5jZG4uYmNlYm9zLmNvbS9zdGF0aWMvdHJhbnNsYXRpb24vaW1nL2hlYWRlci9sb2dvX2U4MzU1NjgucG5nIiwiZXh0ZXJuYWxfbGluayI6ImV4dGVybmFsLWxpbmstdXJsIiwic2VsbGVyX2ZlZV9iYXNpc19wb2ludHMiOjEwMDAsImZlZV9yZWNpcGllbnQiOiIweENENjU5QTFBRUYyNDEzNWY1QzE3Zjg2OGMxQ2Q3YjU1MTc0Q0JEZEUifQ==';

// ------------------------------------

let contractURI = 'https://smart-dao-rel.stars-mine.com/service-api/test1/getOpenseaContractJSON?address=0x87Ae5AB6e5A7F925dCC091F3a2247786D5E26349';
// {
// 	"name": "TestNFT-ABCD",
// 	"description": "TestNFT-ABCD",
// 	"image": "https://smart-dao-rel.stars-mine.com/image.png",
// 	"external_link": "https://smart-dao-rel.stars-mine.com",
// 	"seller_fee_basis_points": 1000,
// 	"fee_recipient": "0x87ae5ab6e5a7f925dcc091f3a2247786d5e26349"
// }

let tokenURI = 'https://api.opensea.io/api/v1/metadata/0x495f947276749ce646f68ac8c248420045cb7b5e/98992976673362451468029657158147997262089202412746295675220817174765200474113';
// {
// 	"name": "Asuki# 11693",
// 	"description": null,
// 	"external_link": null,
// 	"image": "https://i.seadn.io/gae/YOjr3lpp_1Q81BSaKq6TbLG7qWHjE-MXzQQbsp4DlUicblia-uDX__tD8HyIqPe0Mv4vwg6pcd1EbEoBB9KgocVhPsNq7HY7AZ8QUe4?w=500&auto=format",
// 	"animation_url": null
// }

let tokenURI2 = 'https://testnets-api.opensea.io/api/v1/metadata/0xf4910c763ed4e47a585e2d34baa9a4b611ae448c/0x83b6cb4e2482ce9786498d071d6fe63061de853c000000000000010000000032';
// {
// 	"name": "T2",
// 	"description": "The description will be included on the item's detail page underneath its image. Markdown syntax is supported.\n\nThe description will be included on the item's detail page underneath its image. Markdown syntax is supported.\n\nThe description will be included on the item's detail page underneath its image. Markdown syntax is supported.",
// 	"external_link": "https://testnets.opensea.io/asset/create",
// 	"image": "https://i.seadn.io/gae/cl7l14lJz6jR0q1y-7thfgM77D--1kyn_MwKQM1f0_gt9m4y5H0EFlxew4kJSExZPfXH4XBA8Sl_aU1V1WD21jOgea5fDxK27SRMZw?w=500&auto=format",
// 	"animation_url": null
// }